import Foundation
import Testing
@testable import DieselReady

/// The pre-start and post-start checklists on the Checks tab, their links to
/// lessons, notices and the Fault finder, and the in-memory ticks.
@Suite("Checklists")
struct ChecklistContentTests {

    private static func library() throws -> ContentLibrary { try ContentLoader.bundled(.main).load() }

    private static func bundledJSON() throws -> [String: Any] {
        let url = try #require(Bundle.main.resourceURL?.appendingPathComponent("Content/checklists.json"))
        return try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    /// The bundled checklists with one change applied, decoded.
    private static func guide(_ change: (inout [String: Any]) -> Void) throws -> ChecklistGuide {
        var json = try bundledJSON()
        change(&json)
        return try JSONDecoder().decode(ChecklistGuide.self, from: JSONSerialization.data(withJSONObject: json))
    }

    /// Applies a change to one item, found by id.
    private static func changeItem(_ id: String, in json: inout [String: Any], _ change: (inout [String: Any]) -> Void) {
        var lists = json["checklists"] as! [[String: Any]]
        for l in lists.indices {
            var sections = lists[l]["sections"] as! [[String: Any]]
            for s in sections.indices {
                var items = sections[s]["items"] as! [[String: Any]]
                for i in items.indices where items[i]["id"] as? String == id { change(&items[i]) }
                sections[s]["items"] = items
            }
            lists[l]["sections"] = sections
        }
        json["checklists"] = lists
    }

    private static func changeList(_ index: Int, in json: inout [String: Any], _ change: (inout [String: Any]) -> Void) {
        var lists = json["checklists"] as! [[String: Any]]
        change(&lists[index])
        json["checklists"] = lists
    }

    // MARK: Bundled content

    @Test("Pre-start and post-start checklists decode, in order, built on WOBBLE")
    func bundledChecklists() throws {
        let guide = try #require(try Self.library().checks)
        #expect(guide.checklists.map(\.id) == ["pre-start", "post-start"])
        #expect(guide.mnemonic.name == "WOBBLE")
        #expect(guide.mnemonic.letters.map(\.word) == ["Water", "Oil", "Belts", "Bilges", "Leaks and levels", "Exhaust"])
        #expect(guide.mnemonic.summary.hasPrefix("WOBBLE is a widely used memory aid"))

        let pre = try #require(guide.checklist(withID: "pre-start"))
        #expect(pre.engineRunning == false)
        #expect(pre.sections.map(\.title) == ["Water", "Oil", "Belts", "Bilges", "Leaks and levels", "Before you start"])
        #expect(pre.sections.compactMap(\.letter) == ["W", "O", "B", "B", "L"])
        let before = try #require(pre.sections.last).items.map(\.id)
        #expect(before == ["pre-ventilation", "pre-propeller", "pre-neutral", "pre-stop-control"])

        let post = try #require(guide.checklist(withID: "post-start"))
        #expect(post.engineRunning)
        #expect(post.sections.first?.letter == "E")
        #expect(post.banner?.hasPrefix("Engine running: observe only") == true)
        #expect(post.items.allSatisfy { $0.action == .observe }, "running engine: observe only")
        #expect(guide.allItems.allSatisfy { $0.action != .engineer })
    }

    @Test("The no-exhaust-water check references the overheating notice instead of copying it")
    func exhaustReferencesNotice() throws {
        let library = try Self.library()
        let guide = try #require(library.checks)
        let item = try #require(guide.allItems.first { $0.id == "post-exhaust-water" })
        #expect(item.noticeIDs == ["overheating-stop"])
        #expect(item.detail.contains("stop the engine"))
        let notice = try #require(library.safety?.notice(withID: "overheating-stop"))
        #expect(notice.text == SafetyContentTests.verbatim["overheating-stop"]?.text)
        for text in guide.allItems.flatMap({ [$0.title, $0.detail] }) + guide.checklists.compactMap(\.banner) {
            #expect(!text.contains(notice.text), "notice wording is referenced by id, not copied")
        }
    }

    @Test("Every check links to a lesson, and the noise and smoke check to the Fault finder")
    func linksResolve() throws {
        let library = try Self.library()
        let guide = try #require(library.checks)
        for item in guide.allItems {
            #expect(library.lesson(withID: item.lessonId) != nil, "\(item.id) lesson")
        }
        let smoke = try #require(guide.allItems.first { $0.id == "post-noise-smoke" })
        #expect(smoke.symptomId == "exhaust-smoke")
        #expect(library.faults?.symptom(withID: "exhaust-smoke") != nil)
        #expect(guide.allItems.first { $0.id == "pre-seacock" }?.lessonId == "m03-l02")
    }

    @Test("Lesson 7.1 follows WOBBLE and links to both checklists, which link back")
    func lessonMatchesChecklists() throws {
        let library = try Self.library()
        let lesson = try #require(library.lesson(withID: "m07-l01"))
        #expect(lesson.checklistIDs == ["pre-start", "post-start"])
        let guide = try #require(library.checks)
        #expect(guide.checklists.allSatisfy { $0.lessonId == lesson.id })
        #expect(lesson.steps.compactMap(\.title) == [
            "W: Water", "O: Oil", "B: Belts", "B: Bilges", "L: Leaks and levels", "Before you start", "E: Exhaust, once running",
        ])
        #expect(lesson.intro.hasPrefix("WOBBLE is a widely used memory aid"))
        #expect(lesson.noticeIDs.contains("overheating-stop"))
        // The same points in the lesson as in the checklists.
        let text = lesson.steps.map(\.text).joined(separator: " ").lowercased()
        for phrase in ["never open a hot pressure cap", "seacock is open", "milky", "as your engine handbook specifies",
                       "bilge", "isolator", "ventilate", "neutral", "stop control", "within a few seconds",
                       "stop the engine", "oil pressure and charging lights", "without reaching near moving parts"] {
            #expect(text.contains(phrase), "lesson 7.1 mentions \(phrase)")
        }
    }

    @Test("Checklists give no engine-specific figures, and every item is a draft")
    func noFiguresAndDraft() throws {
        let guide = try #require(try Self.library().checks)
        let texts = guide.allItems.flatMap { [$0.title, $0.detail] }
            + guide.checklists.flatMap { [$0.title, $0.subtitle, $0.intro, $0.banner ?? ""] }
        for text in texts {
            #expect(text.rangeOfCharacter(from: .decimalDigits) == nil, "no figures: \(text)")
        }
        #expect(guide.allItems.allSatisfy { $0.reviewStatus == .draft })
        #expect(guide.checklists.allSatisfy { $0.reviewStatus == .draft })
    }

    @Test("At least six questions on the checks, safety-critical ones in the mock test pool")
    func checklistQuestions() throws {
        let library = try Self.library()
        let ids = (22...30).map { String(format: "m07-q%03d", $0) }
        let questions = library.allQuestions.filter { ids.contains($0.id) }
        #expect(questions.count == ids.count)
        #expect(questions.allSatisfy { $0.lessonId == "m07-l01" && $0.reviewStatus == .draft })
        #expect(questions.filter(\.isSafetyCritical).count >= 6)
        let noWater = try #require(questions.first { $0.prompt.contains("no cooling water") })
        #expect(noWater.noticeIDs == ["overheating-stop"] && noWater.isScenario)

        // Mock tests draw on them.
        var seen = Set<String>()
        for seed in UInt64(1)...UInt64(60) {
            var rng = SeededGenerator(seed: seed)
            seen.formUnion(QuestionSelector.select(.mock, from: library, using: &rng).questions.map(\.id))
        }
        #expect(!seen.isDisjoint(with: ids), "the new questions appear in mock tests")
    }

    // MARK: Validator rules

    @Test("Bundled checklists pass validation")
    func bundledValid() throws {
        let library = try Self.library()
        let guide = try #require(library.checks)
        #expect(ContentLoader.validate(guide, library: library).isEmpty)
    }

    @Test("Unknown lessons, notices and symptoms are reported")
    func brokenLinks() throws {
        let library = try Self.library()
        let guide = try Self.guide { json in
            Self.changeItem("pre-coolant", in: &json) { $0["lessonId"] = "m09-l01" }
            Self.changeItem("pre-oil-condition", in: &json) { $0["safetyNoticeIds"] = ["no-such-notice"] }
            Self.changeItem("post-noise-smoke", in: &json) { $0["symptomId"] = "squealing" }
        }
        let problems = ContentLoader.validate(guide, library: library)
        #expect(problems.contains("pre-coolant: links to unknown lesson m09-l01"))
        #expect(problems.contains("pre-oil-condition: unknown safety notice no-such-notice"))
        #expect(problems.contains("post-noise-smoke: links to unknown symptom squealing"))
    }

    @Test("Running-engine checks must be observe only with a banner; no engineer-only checks")
    func runningRules() throws {
        let library = try Self.library()
        let guide = try Self.guide { json in
            Self.changeItem("post-recheck-leaks", in: &json) { $0["action"] = "owner" }
            Self.changeItem("pre-fuel", in: &json) { $0["action"] = "engineer" }
            Self.changeList(1, in: &json) { $0["banner"] = " " }
        }
        let problems = ContentLoader.validate(guide, library: library)
        #expect(problems.contains("post-recheck-leaks: engine is running, so the check must be observe only"))
        #expect(problems.contains("pre-fuel: checklists hold observe and owner checks only"))
        #expect(problems.contains("post-start: engine-running checklist needs a banner"))
    }

    @Test("Sections must spell the memory aid, and the lesson must link back")
    func mnemonicAndBackLink() throws {
        let library = try Self.library()
        let guide = try Self.guide { json in
            Self.changeList(0, in: &json) { list in
                var sections = list["sections"] as! [[String: Any]]
                sections.swapAt(0, 1)
                list["sections"] = sections
                list["lessonId"] = "m01-l01"
            }
        }
        let problems = ContentLoader.validate(guide, library: library)
        #expect(problems.contains("checklists: lettered sections OWBBLE do not match WOBBLE"))
        #expect(problems.contains("checklists: lettered section titles do not match the memory aid words"))
        #expect(problems.contains("pre-start: lesson m01-l01 does not link back to it"))
    }

    @Test("Duplicate ids and a missing checklist are reported")
    func duplicatesAndMissing() throws {
        let library = try Self.library()
        let guide = try Self.guide { json in
            Self.changeItem("pre-strainer", in: &json) { $0["id"] = "pre-seacock" }
            var lists = json["checklists"] as! [[String: Any]]
            lists.removeLast()
            json["checklists"] = lists
        }
        let problems = ContentLoader.validate(guide, library: library)
        #expect(problems.contains("checklists: duplicate id pre-seacock"))
        #expect(problems.contains("checklists: expected pre-start, post-start in that order"))
    }

    @Test("Release rules require the checklists, and lesson links must resolve")
    func releaseRequiresChecklists() throws {
        let bundled = try Self.library()
        let library = ContentLibrary(schemaVersion: bundled.schemaVersion, modules: bundled.modules,
                                     faults: bundled.faults, safety: bundled.safety, info: bundled.info, checks: nil)
        let release = ContentLoader.validate(library, rules: .release)
        #expect(release.contains("manifest: no checklists file"))
        #expect(release.contains("m07-l01: links to unknown checklist pre-start"))
        let structural = ContentLoader.validate(library, rules: .structural)
        #expect(!structural.contains("manifest: no checklists file"))
    }

    // MARK: Ticks

    @Test("Ticks toggle, count per checklist and reset, in memory only")
    func ticks() throws {
        let guide = try #require(try Self.library().checks)
        let pre = try #require(guide.checklist(withID: "pre-start"))
        let post = try #require(guide.checklist(withID: "post-start"))
        var ticks = ChecklistTicks()
        #expect(ticks.isEmpty && ticks.count(in: pre) == 0)

        ticks.toggle("pre-coolant")
        ticks.toggle("pre-seacock")
        ticks.toggle("post-exhaust-water")
        #expect(ticks.count(in: pre) == 2)
        #expect(ticks.count(in: post) == 1)
        #expect(ticks.isTicked("pre-seacock"))

        ticks.toggle("pre-seacock")
        #expect(!ticks.isTicked("pre-seacock"))
        #expect(ticks.count(in: pre) == 1)

        ticks.reset()
        #expect(ticks.isEmpty && ticks.count(in: pre) == 0 && ticks.count(in: post) == 0)
    }
}
