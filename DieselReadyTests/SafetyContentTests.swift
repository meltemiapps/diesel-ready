import Foundation
import Testing
@testable import DieselReady

/// The safety structure of the content: verbatim notices, warnings before
/// steps, action levels on procedures, applicability tags and content info.
@Suite("Safety content")
struct SafetyContentTests {

    /// The approved replacement wording, which must appear unchanged.
    static let verbatim: [String: (title: String, text: String)] = [
        "wet-exhaust-waterlock": (
            "WARNING — WET EXHAUST / WATERLOCK",
            "If the engine repeatedly cranks but does not start, stop and follow the engine and exhaust-system manufacturer's procedure. On many wet-exhaust installations the seawater pump continues to deliver water while cranking; without exhaust gas flow, water can accumulate and enter the engine. **Never run the engine with the raw-water seacock closed.** Some manufacturers specify a controlled seawater-isolation procedure for extended troubleshooting. Use it only if it is documented for that installation, and positively confirm the seacock is **OPEN BEFORE THE ENGINE IS ALLOWED TO RUN**. If water ingestion is suspected, do not crank again; seek qualified assistance."
        ),
        "high-pressure-fuel": (
            "WARNING — HIGH-PRESSURE FUEL INJECTION",
            "The steps in this lesson describe only manufacturer-approved **low-pressure** bleeding arrangements. Do not loosen injector pipes, common-rail components or other high-pressure fuel connections. Diesel fuel under high pressure can penetrate skin and cause severe injury; suspected injection injury requires immediate emergency medical treatment. Stop the engine, prevent accidental starting, contain spills and follow the exact handbook procedure. If the system does not have an approved owner bleeding method, use a qualified engineer."
        ),
        "oil-pressure-stop": (
            "STOP-ENGINE CONDITION",
            "If the oil-pressure alarm activates or the gauge indicates abnormally low pressure, reduce power and stop the engine **as soon as vessel safety permits**. Secure the vessel first. Do not restart simply to test whether the alarm clears. Once stopped, check oil level and obvious leaks in accordance with the handbook. If the cause is not clear and corrected, seek engineering assistance."
        ),
        "overheating-stop": (
            "STOP-ENGINE CONDITION",
            "If the engine overheats or cooling-water flow is lost, reduce power and stop the engine as soon as the vessel is safe. Do not open a hot coolant pressure cap or touch hot hoses/exhaust components. Allow the engine to cool before checking the seawater intake, strainer, pump drive, impeller and coolant level as applicable. Do not restart until the cause is corrected and the cooling circuit is confirmed ready."
        ),
    ]

    static let hoseWording = "All hoses and fittings connected to hull openings must be suitable for the installation, correctly secured and inspected for leaks and deterioration. Use the clamp type, size, number and placement specified by the hose/fitting manufacturer and applicable vessel guidance; double clamping is not a universal substitute for correct fit and installation."

    private static func library() throws -> ContentLibrary { try ContentLoader.bundled(.main).load() }

    // MARK: Bundled content

    @Test("The four shared notices match the approved wording exactly")
    func noticesVerbatim() throws {
        let safety = try #require(try Self.library().safety)
        for (id, expected) in Self.verbatim {
            let notice = try #require(safety.notice(withID: id), "missing \(id)")
            #expect(notice.title == expected.title, "\(id) title")
            #expect(notice.text == expected.text, "\(id) text")
        }
        #expect(safety.notice(withID: "oil-pressure-stop")?.level == .stop)
        #expect(safety.notice(withID: "high-pressure-fuel")?.level == .warning)
    }

    @Test("Each notice appears in the lessons, quiz feedback and Fault finder it applies to")
    func noticesEverywhere() throws {
        let library = try Self.library()
        func lessonNotices(_ id: String) -> [String] { library.lesson(withID: id)?.noticeIDs ?? [] }
        func questionNotices(_ id: String) -> [String] { library.allQuestions.first { $0.id == id }?.noticeIDs ?? [] }

        #expect(lessonNotices("m08-l02").contains("wet-exhaust-waterlock"))
        #expect(lessonNotices("m02-l04").contains("high-pressure-fuel"))
        #expect(lessonNotices("m04-l04").contains("oil-pressure-stop"))
        #expect(lessonNotices("m08-l04") == ["oil-pressure-stop", "overheating-stop"])
        #expect(lessonNotices("m03-l05").contains("overheating-stop"))
        #expect(questionNotices("m08-q009").contains("wet-exhaust-waterlock"))
        #expect(questionNotices("m04-q016").contains("oil-pressure-stop"))
        #expect(questionNotices("m03-q020").contains("overheating-stop"))
        #expect(questionNotices("m02-q014").contains("high-pressure-fuel"))
        let faults = try #require(library.faults)
        #expect(faults.symptom(withID: "wont-start")?.noticeIDs.first == "wet-exhaust-waterlock")
    }

    @Test("The hose and fitting wording replaces the two-clip advice")
    func hoseWording() throws {
        let lesson = try #require(try Self.library().lesson(withID: "m03-l02"))
        #expect(lesson.steps.contains { $0.text == Self.hoseWording })
        #expect(!lesson.steps.contains { $0.text.contains("two stainless clips") })
    }

    @Test("Corrected statements no longer appear anywhere")
    func correctedStatementsGone() throws {
        let library = try Self.library()
        let lessonText = library.allLessons.flatMap { l in
            [l.intro, l.caution ?? ""] + l.steps.map(\.text)
        }.joined(separator: " ")
        #expect(!lessonText.contains("The two liquids never mix"))
        #expect(!lessonText.contains("whether to close the raw water seacock"))
        #expect(!lessonText.contains("never loosen a high-pressure pipe while the engine is running"))
        #expect(!lessonText.contains("the alternator is not charging"))
        #expect(lessonText.contains("The circuits are normally separate; internal leakage or failure can allow mixing."))
        let questions = library.allQuestions.map { $0.prompt + " " + $0.options.joined(separator: " ") }.joined(separator: " ")
        #expect(!questions.lowercased().contains("most common"))
        #expect(!questions.lowercased().contains("most likely"))
    }

    @Test("Every procedural step has an action level and every hazardous procedure warns first")
    func proceduresAreLabelled() throws {
        for lesson in try Self.library().allLessons where lesson.handsOn {
            for (index, step) in lesson.steps.enumerated() {
                #expect(step.action != nil, "\(lesson.id) step \(index + 1)")
            }
            if lesson.isHazardousProcedure {
                #expect(lesson.hasWarningBeforeSteps, "\(lesson.id) needs a warning before its steps")
            }
        }
    }

    @Test("Applicability tags cover the installation types the audit lists")
    func tags() throws {
        let library = try Self.library()
        let safety = try #require(library.safety)
        #expect(Set(safety.tags.map(\.id)) == [
            "mechanical-injection", "common-rail", "direct-cooling", "heat-exchanger", "keel-cooling",
            "packed-gland", "shaft-seal", "lead-acid", "lithium",
        ])
        #expect(library.lesson(withID: "m06-l03")?.tagIDs == ["packed-gland", "shaft-seal"])
        #expect(library.lesson(withID: "m05-l05")?.tagIDs == ["lead-acid", "lithium"])
        #expect(library.lesson(withID: "m03-l01")?.tagIDs.contains("keel-cooling") == true)
        #expect(library.lesson(withID: "m02-l03")?.tagIDs.contains("common-rail") == true)
    }

    @Test("Content info shows version 1.2, the review date and engineer approval")
    func contentInfo() throws {
        let info = try #require(try Self.library().info)
        #expect(info.version == "1.2")
        #expect(info.status == "reviewed")
        #expect(info.engineerApproval == "approved")
        #expect(info.isApproved)
        #expect(info.reviewDateValue != nil)
        #expect(ContentInfoFormat.date(info.reviewDate) == "20 November 2026")
        #expect(info.changeLog.first?.version == "1.2")
    }

    @Test("At least 150 questions remain, and every item is reviewed")
    func volumeAndReviewed() throws {
        let library = try Self.library()
        #expect(library.allQuestions.count >= 150)
        #expect(library.allLessons.allSatisfy { $0.reviewStatus == .reviewed })
        #expect(library.allQuestions.allSatisfy { $0.reviewStatus == .reviewed })
        #expect(library.faults?.symptoms.allSatisfy { $0.reviewStatus == .reviewed } == true)
        #expect(library.checks?.allItems.allSatisfy { $0.reviewStatus == .reviewed } == true)
        #expect(ContentLoader.unreviewedItems(in: library).isEmpty)
    }

    @Test("Release rules fail on any draft item or unapproved content info; debug launch rules do not")
    func releaseRequiresReviewed() throws {
        let bundled = try Self.library()
        let module = try #require(bundled.modules.first)
        var lessons = module.lessons
        let first = lessons[0]
        lessons[0] = Lesson(id: first.id, title: first.title, estimatedMinutes: first.estimatedMinutes,
                            intro: first.intro, diagram: first.diagram, steps: first.steps, caution: first.caution,
                            handsOn: first.handsOn, reviewStatus: .draft, safetyNoticeIds: first.safetyNoticeIds,
                            appliesTo: first.appliesTo, checklistIds: first.checklistIds)
        let draftModule = Module(id: module.id, number: module.number, title: module.title, summary: module.summary,
                                 lessons: lessons, questions: module.questions)
        let old = try #require(bundled.info)
        let pending = ContentInfo(version: old.version, status: "draft", reviewDate: old.reviewDate,
                                  engineerApproval: "pending", changeLog: old.changeLog)
        let library = ContentLibrary(schemaVersion: bundled.schemaVersion,
                                     modules: [draftModule] + bundled.modules.dropFirst(),
                                     faults: bundled.faults, safety: bundled.safety, info: pending, checks: bundled.checks)
        #expect(!pending.isApproved)

        let release = ContentLoader.validate(library, rules: .release)
        #expect(release.contains("\(first.id): reviewStatus is draft, release content must be reviewed"))
        #expect(release.contains("contentInfo: status is draft, release content must be reviewed"))
        #expect(release.contains("contentInfo: engineerApproval is pending, expected approved"))
        #expect(ContentLoader.validate(library, rules: .structural).isEmpty)
        #expect(ContentLoader.validate(bundled, rules: .release).isEmpty)
        // Tests run a Debug build, where draft content can still be tried out.
        #expect(!ContentRules.launch.requireReviewed)
    }

    @Test("Notice markup renders as plain text for VoiceOver")
    func markdownPlainText() {
        #expect("Do **not** crank.".plainFromMarkdown == "Do not crank.")
        #expect("No markup".plainFromMarkdown == "No markup")
    }

    // MARK: Validator rules

    private static let safety: SafetyGuide = {
        let notices = SafetyGuide.requiredNoticeIDs.map { SafetyNotice(id: $0, level: .stop, title: "T", text: "X") }
        let levels = ActionLevel.allCases.map { ActionLevelInfo(id: $0, label: $0.rawValue, description: "D") }
        return SafetyGuide(notices: notices, actionLevels: levels,
                           tags: [ApplicabilityTag(id: "common-rail", group: "Fuel injection", label: "Common rail")])
    }()

    private static func lesson(steps: [Step], handsOn: Bool = true, caution: String? = nil,
                               notices: [String]? = nil, tags: [String]? = nil) -> Lesson {
        Lesson(id: "m01-l01", title: "L", estimatedMinutes: 5, intro: "I", diagram: nil, steps: steps,
               caution: caution, handsOn: handsOn, reviewStatus: .draft, safetyNoticeIds: notices, appliesTo: tags)
    }

    @Test("A procedural step without an action level fails")
    func stepWithoutAction() {
        let lesson = Self.lesson(steps: [Step(title: nil, text: "Look", action: .observe), Step(title: nil, text: "Undo it")],
                                 caution: "Hot.")
        #expect(ContentLoader.validateSafety(of: lesson, safety: Self.safety)
            .contains("m01-l01 step 2: procedural step has no action level"))
        // Explanatory lessons need no action levels.
        let reading = Self.lesson(steps: [Step(title: nil, text: "How it works")], handsOn: false)
        #expect(ContentLoader.validateSafety(of: reading, safety: Self.safety).isEmpty)
    }

    @Test("A hazardous procedure with no warning before its steps fails")
    func hazardWithoutWarning() {
        let steps = [Step(title: nil, text: "Look", action: .observe), Step(title: nil, text: "Open it", action: .owner)]
        #expect(ContentLoader.validateSafety(of: Self.lesson(steps: steps), safety: Self.safety)
            .contains("m01-l01: hazardous procedure has no warning before its steps"))
        #expect(ContentLoader.validateSafety(of: Self.lesson(steps: steps, caution: "Hot parts."), safety: Self.safety).isEmpty)
        #expect(ContentLoader.validateSafety(of: Self.lesson(steps: steps, notices: ["overheating-stop"]), safety: Self.safety).isEmpty)
        // Observe-only procedures are not hazardous.
        let look = [Step(title: nil, text: "Look", action: .observe)]
        #expect(ContentLoader.validateSafety(of: Self.lesson(steps: look), safety: Self.safety).isEmpty)
    }

    @Test("A warning inside the steps, after earlier steps, fails")
    func warningAfterSteps() {
        let steps = [Step(title: nil, text: "Open the cover", action: .owner),
                     Step(title: "Caution", text: "The cover may be hot.", action: .observe),
                     Step(title: nil, text: "STOP if water sprays out.", action: .observe)]
        let problems = ContentLoader.validateSafety(of: Self.lesson(steps: steps, caution: "Hot."), safety: Self.safety)
        #expect(problems.contains { $0.hasPrefix("m01-l01 step 2: contains a warning") })
        #expect(problems.contains { $0.hasPrefix("m01-l01 step 3: contains a warning") })
        #expect(!problems.contains { $0.hasPrefix("m01-l01 step 1") })
        // An ordinary sentence starting with "Stop" is an instruction, not a marker.
        #expect(!ContentLoader.containsWarningMarker("Stop the engine first."))
    }

    @Test("Unknown notices and tags, and rankings in lessons, fail")
    func unknownReferences() {
        let lesson = Self.lesson(steps: [Step(title: nil, text: "The most common cause is air.", action: .observe)],
                                 notices: ["nope"], tags: ["common-rail", "wind-power"])
        let problems = ContentLoader.validateSafety(of: lesson, safety: Self.safety)
        #expect(problems.contains("m01-l01: unknown safety notice nope"))
        #expect(problems.contains("m01-l01: unknown applicability tag wind-power"))
        #expect(problems.contains("m01-l01: ranks causes with \"most common\""))
    }

    @Test("Missing required notices and bad action levels fail")
    func safetyGuideRules() {
        let guide = SafetyGuide(notices: [SafetyNotice(id: "oil-pressure-stop", level: .stop, title: "T", text: " ")],
                                actionLevels: [ActionLevelInfo(id: .owner, label: "Owner", description: "D")], tags: [])
        let problems = ContentLoader.validate(guide)
        #expect(problems.contains("safety: missing notice wet-exhaust-waterlock"))
        #expect(problems.contains("safety: notice oil-pressure-stop has no title or text"))
        #expect(problems.contains("safety: actionLevels must list observe, owner and engineer once each"))
    }

    @Test("Content info needs a real date, an approval entry and a matching change log")
    func contentInfoRules() {
        let info = ContentInfo(version: "2.0", status: "draft", reviewDate: "2026-13-40", engineerApproval: "",
                               changeLog: [ChangeLogEntry(version: "1.9", date: "soon", summary: "S")])
        let problems = ContentLoader.validate(info)
        #expect(problems.contains("contentInfo: reviewDate 2026-13-40 is not yyyy-MM-dd"))
        #expect(problems.contains("contentInfo: engineerApproval is empty"))
        #expect(problems.contains("contentInfo: the first change log entry must be version 2.0"))
        #expect(problems.contains("contentInfo: change log date soon is not yyyy-MM-dd"))
    }

    @Test("Release rules require the safety file and content info")
    func releaseNeedsSafety() {
        let library = ContentLibrary(schemaVersion: 2, modules: [])
        var rules = ContentRules.structural
        rules.requireSafetyContent = true
        let problems = ContentLoader.validate(library, rules: rules)
        #expect(problems.contains("manifest: no safety file"))
        #expect(problems.contains("manifest: no contentInfo"))
    }
}
