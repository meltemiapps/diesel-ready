import Foundation

/// Decodes and validates the bundled JSON content.
///
/// Pure and synchronous so it can be unit-tested with in-memory data.
struct ContentLoader: Sendable {
    /// Highest manifest schema version this build understands.
    static let supportedSchemaVersion = 2
    static let contentDirectory = "Content"

    enum LoadError: Error, Equatable, CustomStringConvertible {
        case missingFile(String)
        case unreadable(file: String, reason: String)
        case unsupportedSchema(Int)
        case invalid([String])

        var description: String {
            switch self {
            case .missingFile(let name):
                "Missing content file: \(name)"
            case .unreadable(let file, let reason):
                "Could not read \(file): \(reason)"
            case .unsupportedSchema(let version):
                "Content schema version \(version) is newer than this app supports."
            case .invalid(let problems):
                "Content failed validation:\n" + problems.joined(separator: "\n")
            }
        }
    }

    /// Volume rules applied on top of the structural checks.
    var rules: ContentRules = .release

    /// Supplies the raw bytes for a path relative to the content directory.
    let dataForPath: @Sendable (String) throws -> Data

    /// Loader that reads from the `Content` folder inside a bundle.
    static func bundled(_ bundle: Bundle = .main) -> ContentLoader {
        // Resolve the folder here so the closure only captures a Sendable URL.
        let root = bundle.resourceURL?.appendingPathComponent(contentDirectory, isDirectory: true)
        return ContentLoader { path in
            guard let root else { throw LoadError.missingFile(path) }
            let url = root.appendingPathComponent(path)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw LoadError.missingFile(path)
            }
            return try Data(contentsOf: url)
        }
    }

    func load() throws -> ContentLibrary {
        let manifest: ContentManifest = try decode("manifest.json")
        guard manifest.schemaVersion <= Self.supportedSchemaVersion else {
            throw LoadError.unsupportedSchema(manifest.schemaVersion)
        }
        let modules: [Module] = try manifest.modules.map { try decode("modules/\($0)") }
        let faults: FaultGuide? = try manifest.faults.map { try decode($0) }
        let safety: SafetyGuide? = try manifest.safety.map { try decode($0) }
        let checks: ChecklistGuide? = try manifest.checklists.map { try decode($0) }
        let library = ContentLibrary(schemaVersion: manifest.schemaVersion, modules: modules, faults: faults,
                                     safety: safety, info: manifest.contentInfo, checks: checks)

        let problems = Self.validate(library, rules: rules)
        guard problems.isEmpty else { throw LoadError.invalid(problems) }
        return library
    }

    private func decode<T: Decodable>(_ path: String) throws -> T {
        let data: Data
        do {
            data = try dataForPath(path)
        } catch let error as LoadError {
            throw error
        } catch {
            throw LoadError.unreadable(file: path, reason: error.localizedDescription)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LoadError.unreadable(file: path, reason: String(describing: error))
        }
    }

    /// Structural checks that the JSON schema alone cannot express.
    /// Returns a human-readable list of problems; empty means valid.
    static func validate(_ library: ContentLibrary, rules: ContentRules = .release) -> [String] {
        var problems: [String] = []
        var seenIDs = Set<String>()
        var seenPrompts: [String: String] = [:]

        func checkUnique(_ id: String) {
            if !seenIDs.insert(id).inserted { problems.append("Duplicate id: \(id)") }
        }

        for (index, module) in library.modules.enumerated() {
            checkUnique(module.id)
            if module.number != index + 1 {
                problems.append("\(module.id): number \(module.number) does not match manifest position \(index + 1)")
            }
            if module.lessons.isEmpty {
                problems.append("\(module.id): has no lessons")
            } else if !rules.lessonsPerModule.contains(module.lessons.count) {
                problems.append("\(module.id): has \(module.lessons.count) lessons, expected \(rules.lessonsPerModule.lowerBound) to \(rules.lessonsPerModule.upperBound)")
            }
            for lesson in module.lessons {
                let count = module.questions(forLesson: lesson.id).count
                if count < rules.minQuestionsPerLesson {
                    problems.append("\(lesson.id): has \(count) questions, needs at least \(rules.minQuestionsPerLesson)")
                }
            }
            if rules.requireEveryDifficultyPerModule {
                let present = Set(module.questions.map(\.difficulty))
                for level in 1...3 where !present.contains(level) {
                    problems.append("\(module.id): has no difficulty \(level) questions")
                }
            }

            let lessonIDs = Set(module.lessons.map(\.id))
            for lesson in module.lessons {
                checkUnique(lesson.id)
                if lesson.steps.isEmpty { problems.append("\(lesson.id): has no steps") }
                if lesson.estimatedMinutes <= 0 { problems.append("\(lesson.id): estimatedMinutes must be positive") }
                if let diagram = lesson.diagram,
                   let expected = Diagram.labelCounts[diagram.kind],
                   !expected.contains(diagram.labels.count) {
                    let range = expected.count == 1 ? "\(expected.lowerBound)" : "\(expected.lowerBound) to \(expected.upperBound)"
                    problems.append("\(lesson.id): diagram \(diagram.kind) has \(diagram.labels.count) labels, expected \(range)")
                }
                problems += validateSafety(of: lesson, safety: library.safety)
            }

            for question in module.questions {
                checkUnique(question.id)
                let key = normalisedPrompt(question.prompt)
                if let earlier = seenPrompts[key] {
                    problems.append("\(question.id): same question text as \(earlier)")
                } else {
                    seenPrompts[key] = question.id
                }
                if question.moduleId != module.id {
                    problems.append("\(question.id): moduleId \(question.moduleId) but stored in \(module.id)")
                }
                if !lessonIDs.contains(question.lessonId) {
                    problems.append("\(question.id): unknown lessonId \(question.lessonId)")
                }
                if question.options.count != 4 {
                    problems.append("\(question.id): has \(question.options.count) options, expected 4")
                }
                if Set(question.options).count != question.options.count {
                    problems.append("\(question.id): has duplicate options")
                }
                if !question.options.indices.contains(question.correctIndex) {
                    problems.append("\(question.id): correctIndex \(question.correctIndex) out of range")
                }
                if !(1...3).contains(question.difficulty) {
                    problems.append("\(question.id): difficulty \(question.difficulty) not in 1...3")
                }
                problems += unknownNotices(question.noticeIDs, in: library.safety, owner: question.id)
                problems += validateCategories(of: question)
                problems += rankingProblems(in: [question.prompt, question.explanation] + question.options,
                                            owner: question.id)
            }
        }

        let total = library.allQuestions.count
        if total < rules.minTotalQuestions {
            problems.append("Only \(total) questions in total, needs at least \(rules.minTotalQuestions)")
        }
        if rules.requireMockBlueprint {
            let blueprint = MockBlueprint.standard
            let safety = library.allQuestions.filter(\.isSafetyCritical).count
            let scenario = library.allQuestions.filter(\.isScenario).count
            if safety < blueprint.minSafetyCritical {
                problems.append("Only \(safety) safety-critical questions, a mock test needs \(blueprint.minSafetyCritical)")
            }
            if scenario < blueprint.minScenario {
                problems.append("Only \(scenario) scenario questions, a mock test needs \(blueprint.minScenario)")
            }
        }

        if let faults = library.faults {
            let noticeIDs = Set(library.safety?.notices.map(\.id) ?? [])
            problems += validate(faults, lessonIDs: Set(library.allLessons.map(\.id)), noticeIDs: noticeIDs)
        }
        if let safety = library.safety {
            problems += validate(safety)
        } else if rules.requireSafetyContent {
            problems.append("manifest: no safety file")
        }
        if let info = library.info {
            problems += validate(info)
        } else if rules.requireSafetyContent {
            problems.append("manifest: no contentInfo")
        }
        if let checks = library.checks {
            problems += validate(checks, library: library)
        } else if rules.requireChecklists {
            problems.append("manifest: no checklists file")
        }
        for lesson in library.allLessons {
            if Set(lesson.checklistIDs).count != lesson.checklistIDs.count {
                problems.append("\(lesson.id): links to the same checklist twice")
            }
            for id in lesson.checklistIDs where library.checks?.checklist(withID: id) == nil {
                problems.append("\(lesson.id): links to unknown checklist \(id)")
            }
        }
        return problems
    }

    // MARK: Checklists

    /// Checklist checks: required lists present, ids unique, links and notices
    /// resolve, sections match the memory aid, running-engine lists are
    /// observe only with a banner, and every checklist's lesson links back.
    static func validate(_ guide: ChecklistGuide, library: ContentLibrary) -> [String] {
        var problems: [String] = []
        let lessonIDs = Set(library.allLessons.map(\.id))
        let symptomIDs = Set(library.faults?.symptoms.map(\.id) ?? [])
        func blank(_ text: String?) -> Bool { (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if blank(guide.reminder) { problems.append("checklists: reminder is empty") }
        if blank(guide.mnemonic.name) || blank(guide.mnemonic.summary) {
            problems.append("checklists: memory aid needs a name and summary")
        }
        let listIDs = guide.checklists.map(\.id)
        if listIDs != ChecklistGuide.requiredChecklistIDs {
            problems.append("checklists: expected \(ChecklistGuide.requiredChecklistIDs.joined(separator: ", ")) in that order")
        }

        // The lettered sections, read across every list in order, spell the memory aid.
        let sectionLetters = guide.checklists.flatMap(\.sections).compactMap(\.letter)
        if sectionLetters != guide.mnemonic.letters.map(\.letter) {
            problems.append("checklists: lettered sections \(sectionLetters.joined()) do not match \(guide.mnemonic.name)")
        }
        let aidName = guide.mnemonic.name.uppercased()
        if aidName != guide.mnemonic.letters.map(\.letter).joined().uppercased() {
            problems.append("checklists: \(guide.mnemonic.name) letters do not spell its name")
        }
        let words = guide.checklists.flatMap(\.sections).filter { $0.letter != nil }.map(\.title)
        if words != guide.mnemonic.letters.map(\.word) {
            problems.append("checklists: lettered section titles do not match the memory aid words")
        }

        var seen = Set<String>()
        func checkUnique(_ id: String) {
            if !seen.insert(id).inserted { problems.append("checklists: duplicate id \(id)") }
        }
        for list in guide.checklists {
            checkUnique(list.id)
            if blank(list.title) || blank(list.subtitle) || blank(list.intro) {
                problems.append("\(list.id): needs a title, subtitle and intro")
            }
            if list.sections.isEmpty { problems.append("\(list.id): has no sections") }
            if !lessonIDs.contains(list.lessonId) {
                problems.append("\(list.id): links to unknown lesson \(list.lessonId)")
            } else if library.lesson(withID: list.lessonId)?.checklistIDs.contains(list.id) != true {
                problems.append("\(list.id): lesson \(list.lessonId) does not link back to it")
            }
            if list.engineRunning && blank(list.banner) {
                problems.append("\(list.id): engine-running checklist needs a banner")
            }
            for section in list.sections {
                checkUnique("\(list.id)/\(section.id)")
                if section.items.isEmpty { problems.append("\(list.id)/\(section.id): has no items") }
                if blank(section.title) { problems.append("\(list.id)/\(section.id): has no title") }
                for item in section.items {
                    let id = item.id
                    checkUnique(id)
                    if blank(item.title) || blank(item.detail) { problems.append("\(id): needs a title and detail") }
                    if item.action == .engineer {
                        problems.append("\(id): checklists hold observe and owner checks only")
                    }
                    if list.engineRunning && item.action != .observe {
                        problems.append("\(id): engine is running, so the check must be observe only")
                    }
                    if !lessonIDs.contains(item.lessonId) {
                        problems.append("\(id): links to unknown lesson \(item.lessonId)")
                    }
                    if let symptom = item.symptomId, !symptomIDs.contains(symptom) {
                        problems.append("\(id): links to unknown symptom \(symptom)")
                    }
                    problems += unknownNotices(item.noticeIDs, in: library.safety, owner: id)
                    problems += rankingProblems(in: [item.title, item.detail], owner: id)
                }
            }
        }
        return problems
    }

    // MARK: Question categories

    static func validateCategories(of question: Question) -> [String] {
        var problems: [String] = []
        let raw = question.categories ?? []
        let known = Set(QuestionCategory.allCases.map(\.rawValue))
        for category in raw where !known.contains(category) {
            problems.append("\(question.id): unknown category \(category)")
        }
        if Set(raw).count != raw.count { problems.append("\(question.id): lists the same category twice") }
        if !question.noticeIDs.isEmpty && !question.isSafetyCritical {
            problems.append("\(question.id): has a safety notice, so it must be safety-critical")
        }
        return problems
    }

    // MARK: Safety rules

    /// Phrases that rank causes by frequency. The content lists possible
    /// causes without ranking them, so these are not allowed anywhere.
    static let rankingPhrases = ["most common", "most likely", "commonest", "most often", "in order of likelihood"]
    /// Further frequency words not allowed in the Fault finder.
    static let faultRankingPhrases = ["less common", "more common", "less likely", "more likely", "likely first"]

    static func rankingProblems(in texts: [String], owner: String, phrases: [String] = rankingPhrases) -> [String] {
        let joined = texts.joined(separator: " ").lowercased()
        return phrases.filter { joined.contains($0) }.map { "\(owner): ranks causes with \"\($0)\"" }
    }

    /// Words that mark a warning. A step containing one would put a warning
    /// after the steps before it, so warnings must go in `caution` or
    /// `safetyNoticeIds`, which the app shows first.
    static func containsWarningMarker(_ text: String) -> Bool {
        let words = text.components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
        if let first = words.first, ["warning", "caution", "danger"].contains(first.lowercased()) { return true }
        return words.contains { ["WARNING", "CAUTION", "DANGER", "STOP"].contains($0) }
    }

    private static func unknownNotices(_ ids: [String], in safety: SafetyGuide?, owner: String) -> [String] {
        var problems: [String] = []
        for id in ids where safety?.notice(withID: id) == nil {
            problems.append("\(owner): unknown safety notice \(id)")
        }
        if Set(ids).count != ids.count { problems.append("\(owner): lists the same safety notice twice") }
        return problems
    }

    /// Warnings before steps, action levels on procedures, known notices and tags.
    static func validateSafety(of lesson: Lesson, safety: SafetyGuide?) -> [String] {
        var problems = unknownNotices(lesson.noticeIDs, in: safety, owner: lesson.id)
        for tag in lesson.tagIDs where safety?.tag(withID: tag) == nil {
            problems.append("\(lesson.id): unknown applicability tag \(tag)")
        }
        if Set(lesson.tagIDs).count != lesson.tagIDs.count {
            problems.append("\(lesson.id): lists the same applicability tag twice")
        }
        for (index, step) in lesson.steps.enumerated() {
            let number = index + 1
            if lesson.handsOn && step.action == nil {
                problems.append("\(lesson.id) step \(number): procedural step has no action level")
            }
            if containsWarningMarker(step.text) || containsWarningMarker(step.title ?? "") {
                problems.append("\(lesson.id) step \(number): contains a warning, which would come after earlier steps; move it to caution or safetyNoticeIds")
            }
        }
        if lesson.isHazardousProcedure && !lesson.hasWarningBeforeSteps {
            problems.append("\(lesson.id): hazardous procedure has no warning before its steps")
        }
        let texts = [lesson.title, lesson.intro, lesson.caution ?? ""] + lesson.steps.flatMap { [$0.title ?? "", $0.text] }
        problems += rankingProblems(in: texts, owner: lesson.id)
        return problems
    }

    /// Notices, action levels and tags are complete and unique.
    static func validate(_ safety: SafetyGuide) -> [String] {
        var problems: [String] = []
        let ids = safety.notices.map(\.id)
        if Set(ids).count != ids.count { problems.append("safety: duplicate notice id") }
        for notice in safety.notices
        where notice.title.trimmingCharacters(in: .whitespaces).isEmpty || notice.text.trimmingCharacters(in: .whitespaces).isEmpty {
            problems.append("safety: notice \(notice.id) has no title or text")
        }
        for id in SafetyGuide.requiredNoticeIDs where !ids.contains(id) {
            problems.append("safety: missing notice \(id)")
        }
        let levels = safety.actionLevels.map(\.id)
        if Set(levels) != Set(ActionLevel.allCases) || levels.count != ActionLevel.allCases.count {
            problems.append("safety: actionLevels must list observe, owner and engineer once each")
        }
        let tags = safety.tags.map(\.id)
        if Set(tags).count != tags.count { problems.append("safety: duplicate tag id") }
        return problems
    }

    static func validate(_ info: ContentInfo) -> [String] {
        var problems: [String] = []
        if info.reviewDateValue == nil { problems.append("contentInfo: reviewDate \(info.reviewDate) is not yyyy-MM-dd") }
        if info.engineerApproval.trimmingCharacters(in: .whitespaces).isEmpty {
            problems.append("contentInfo: engineerApproval is empty")
        }
        if info.changeLog.first?.version != info.version {
            problems.append("contentInfo: the first change log entry must be version \(info.version)")
        }
        for entry in info.changeLog where ContentInfo.date(from: entry.date) == nil {
            problems.append("contentInfo: change log date \(entry.date) is not yyyy-MM-dd")
        }
        return problems
    }

    /// Lowercased, with punctuation removed and spaces collapsed, so trivially
    /// different copies of the same question are caught.
    static func normalisedPrompt(_ prompt: String) -> String {
        prompt.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Fault finder checks: lesson links resolve, every STOP condition has a
    /// complete card, and the dangerous symptoms open with their notice and card.
    static func validate(_ faults: FaultGuide, lessonIDs: Set<Lesson.ID>, noticeIDs: Set<String>) -> [String] {
        var problems: [String] = []
        var seen = Set<String>()

        if faults.reminder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("faults: reminder is empty")
        }
        let cardIDs = faults.stopCards.map(\.id)
        if Set(cardIDs).count != cardIDs.count { problems.append("faults: duplicate stop card id") }
        for id in FaultGuide.requiredStopCardIDs {
            guard let card = faults.stopCard(withID: id) else {
                problems.append("faults: STOP condition \(id) has no card")
                continue
            }
            let parts = [card.title, card.stop, card.doNotRestart, card.getAssistance]
            if parts.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                problems.append("faults: stop card \(id) needs a title, stop, doNotRestart and getAssistance")
            }
        }
        let cardTexts = faults.stopCards.flatMap { [$0.title, $0.stop, $0.doNotRestart, $0.getAssistance] }
        problems += rankingProblems(in: [faults.intro] + cardTexts, owner: "faults",
                                    phrases: rankingPhrases + faultRankingPhrases)

        for symptom in faults.symptoms {
            let id = symptom.id
            if !seen.insert(id).inserted { problems.append("faults: duplicate symptom id \(id)") }
            if symptom.possibleCauses.isEmpty { problems.append("\(id): has no possible causes") }
            if symptom.checkFirst.isEmpty { problems.append("\(id): has nothing to check first") }
            if symptom.lessonIds.isEmpty { problems.append("\(id): links to no lessons") }
            for lessonID in symptom.lessonIds where !lessonIDs.contains(lessonID) {
                problems.append("\(id): links to unknown lesson \(lessonID)")
            }
            if Set(symptom.lessonIds).count != symptom.lessonIds.count {
                problems.append("\(id): links to the same lesson twice")
            }
            for notice in symptom.noticeIDs where !noticeIDs.contains(notice) {
                problems.append("\(id): unknown safety notice \(notice)")
            }
            for card in symptom.cardIDs where faults.stopCard(withID: card) == nil {
                problems.append("\(id): unknown stop card \(card)")
            }
            if let required = FaultGuide.requiredSymptomSafety[id] {
                if symptom.noticeIDs.first != required.noticeID {
                    problems.append("\(id): must open with safety notice \(required.noticeID)")
                }
                if !symptom.cardIDs.contains(required.stopCardID) {
                    problems.append("\(id): STOP condition \(required.stopCardID) lacks its card")
                }
            }
            let texts = [symptom.title, symptom.summary] + symptom.checkFirst
                + symptom.possibleCauses.flatMap { [$0.title, $0.detail] }
            problems += rankingProblems(in: texts, owner: id, phrases: rankingPhrases + faultRankingPhrases)
        }
        for missing in FaultGuide.requiredSymptomIDs.subtracting(seen).sorted() {
            problems.append("faults: missing symptom \(missing)")
        }
        return problems
    }
}

/// Volume rules for the bundled course. Tests that build tiny libraries use
/// `.structural`, which keeps every other check.
struct ContentRules: Sendable, Equatable {
    var lessonsPerModule: ClosedRange<Int>
    var minQuestionsPerLesson: Int
    var minTotalQuestions: Int
    var requireEveryDifficultyPerModule: Bool
    /// The manifest must list a safety file and content info.
    var requireSafetyContent: Bool
    /// There are enough safety-critical and scenario questions for a mock test.
    var requireMockBlueprint: Bool
    /// The manifest must list the pre-start and post-start checklists.
    var requireChecklists: Bool

    static let release = ContentRules(
        lessonsPerModule: 3...6,
        minQuestionsPerLesson: 3,
        minTotalQuestions: 150,
        requireEveryDifficultyPerModule: true,
        requireSafetyContent: true,
        requireMockBlueprint: true,
        requireChecklists: true
    )

    static let structural = ContentRules(
        lessonsPerModule: 1...Int.max,
        minQuestionsPerLesson: 0,
        minTotalQuestions: 0,
        requireEveryDifficultyPerModule: false,
        requireSafetyContent: false,
        requireMockBlueprint: false,
        requireChecklists: false
    )
}
