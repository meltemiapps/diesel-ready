import Foundation
import Testing
@testable import DieselReady

@Suite("Fault finder content")
struct FaultContentTests {

    // MARK: Bundled content

    @Test("Bundled fault content decodes with all six symptoms and seven stop cards")
    func bundledFaultsDecode() throws {
        let library = try ContentLoader.bundled(.main).load()
        let guide = try #require(library.faults)
        #expect(Set(guide.symptoms.map(\.id)) == FaultGuide.requiredSymptomIDs)
        #expect(guide.symptoms.map(\.title) == [
            "Exhaust smoke", "Won't start", "Overheating", "Stops suddenly", "Low oil pressure", "Not charging",
        ])
        #expect(guide.stopCards.map(\.id) == FaultGuide.requiredStopCardIDs)
        #expect(guide.symptoms.allSatisfy { $0.reviewStatus == .reviewed })
        #expect(guide.symptoms.allSatisfy { !$0.possibleCauses.isEmpty && !$0.checkFirst.isEmpty && !$0.lessonIds.isEmpty })
    }

    @Test("Dangerous symptoms open with their verbatim notice and their stop card")
    func dangerousSymptomsOpenWithSafety() throws {
        let library = try ContentLoader.bundled(.main).load()
        let guide = try #require(library.faults)
        let safety = try #require(library.safety)
        for (id, required) in FaultGuide.requiredSymptomSafety {
            let symptom = try #require(guide.symptom(withID: id))
            #expect(symptom.noticeIDs.first == required.noticeID, "\(id) opens with its notice")
            #expect(symptom.cardIDs.contains(required.stopCardID), "\(id) shows its stop card")
            let notice = try #require(safety.notice(withID: required.noticeID))
            #expect(notice.text == SafetyContentTests.verbatim[required.noticeID]?.text)
        }
        #expect(guide.symptom(withID: "low-oil-pressure")?.checkFirst.first == "Do not restart to see whether the warning clears.")
    }

    @Test("No fault text ranks causes by frequency")
    func noRankings() throws {
        let guide = try #require(try ContentLoader.bundled(.main).load().faults)
        let texts = [guide.intro] + guide.symptoms.flatMap { s in
            [s.summary] + s.checkFirst + s.possibleCauses.flatMap { [$0.title, $0.detail] }
        }
        let all = texts.joined(separator: " ").lowercased()
        for phrase in ContentLoader.rankingPhrases + ContentLoader.faultRankingPhrases {
            #expect(!all.contains(phrase), "\"\(phrase)\" in the Fault finder")
        }
        #expect(!guide.intro.lowercased().contains("most likely first"))
    }

    @Test("The won't-start checks no longer advise closing the seacock to crank")
    func noSeacockClosingAdvice() throws {
        let guide = try #require(try ContentLoader.bundled(.main).load().faults)
        let checks = try #require(guide.symptom(withID: "wont-start")).checkFirst.joined(separator: " ").lowercased()
        #expect(!checks.contains("when to close the raw water seacock"))
        #expect(checks.contains("never run the engine with the raw-water seacock closed"))
    }

    @Test("Every bundled lesson link resolves to a lesson")
    func bundledLinksResolve() throws {
        let library = try ContentLoader.bundled(.main).load()
        let guide = try #require(library.faults)
        for symptom in guide.symptoms {
            for id in symptom.lessonIds {
                #expect(library.lesson(withID: id) != nil, "\(symptom.id) links to \(id)")
            }
        }
    }

    @Test("The closing reminder mentions the handbook and a qualified engineer")
    func reminder() throws {
        let guide = try #require(try ContentLoader.bundled(.main).load().faults)
        #expect(guide.reminder.contains("handbook"))
        #expect(guide.reminder.contains("qualified marine engineer"))
    }

    // MARK: Decoding

    @Test("Fault JSON decodes, with notices and stop cards optional per symptom")
    func decodesFromJSON() throws {
        let library = try Self.loader(faults: Self.faultsJSON()).load()
        let guide = try #require(library.faults)
        #expect(guide.symptoms.count == 6)
        #expect(guide.stopCards.count == 7)
        let overheating = try #require(guide.symptom(withID: "overheating"))
        #expect(overheating.noticeIDs == ["overheating-stop"])
        #expect(overheating.cardIDs == ["overheating"])
        #expect(overheating.possibleCauses.first == FaultCause(title: "Cause 1", detail: "Detail"))
        #expect(overheating.checkFirst == ["Check"])
        let smoke = try #require(guide.symptom(withID: "exhaust-smoke"))
        #expect(smoke.noticeIDs.isEmpty && smoke.cardIDs.isEmpty)
    }

    @Test("A manifest without a faults entry loads with no fault guide")
    func faultsAreOptionalInManifest() throws {
        let loader = ContentLoader.inMemory([
            "manifest.json": #"{"schemaVersion":2,"modules":["a.json"]}"#,
            "modules/a.json": Self.moduleJSON,
        ])
        #expect(try loader.load().faults == nil)
    }

    @Test("A missing faults file is reported by name")
    func missingFaultsFile() {
        let loader = ContentLoader.inMemory([
            "manifest.json": #"{"schemaVersion":2,"modules":["a.json"],"faults":"faults.json"}"#,
            "modules/a.json": Self.moduleJSON,
        ])
        #expect(throws: ContentLoader.LoadError.missingFile("faults.json")) { try loader.load() }
    }

    // MARK: Validation

    @Test("A broken lesson link fails loading")
    func brokenLinkFailsLoad() {
        let loader = Self.loader(faults: Self.faultsJSON(lessonIds: #"["m01-l01","m05-l02"]"#))
        #expect {
            try loader.load()
        } throws: { error in
            guard case ContentLoader.LoadError.invalid(let problems) = error else { return false }
            return problems.contains("exhaust-smoke: links to unknown lesson m05-l02")
                && !problems.contains { $0.contains("m01-l01") }
        }
    }

    @Test("Valid fault content passes validation")
    func validContentPasses() throws {
        _ = try Self.loader(faults: Self.faultsJSON()).load()
    }

    @Test("A STOP condition without its card is reported")
    func missingStopCard() {
        var cards = Self.cards()
        cards.removeAll { $0.id == "fuel-spray" }
        cards[0] = StopCard(id: cards[0].id, title: "T", stop: "S", doNotRestart: " ", getAssistance: "A")
        let guide = FaultGuide(intro: "I", reminder: "R", stopCards: cards, symptoms: Self.symptoms())
        let problems = ContentLoader.validate(guide, lessonIDs: ["m01-l01"], noticeIDs: Self.noticeIDs)
        #expect(problems.contains("faults: STOP condition fuel-spray has no card"))
        #expect(problems.contains("faults: stop card low-oil-pressure needs a title, stop, doNotRestart and getAssistance"))
    }

    @Test("Dangerous symptoms must open with their notice and link their card")
    func requiredSymptomSafety() {
        let symptoms = Self.symptoms().map { s in
            s.id == "overheating"
                ? Symptom(id: s.id, title: s.title, summary: s.summary, safetyNoticeIds: nil, stopCardIds: nil,
                          possibleCauses: s.possibleCauses, checkFirst: s.checkFirst, lessonIds: s.lessonIds,
                          reviewStatus: .draft)
                : s
        }
        let guide = FaultGuide(intro: "I", reminder: "R", stopCards: Self.cards(), symptoms: symptoms)
        let problems = ContentLoader.validate(guide, lessonIDs: ["m01-l01"], noticeIDs: Self.noticeIDs)
        #expect(problems.contains("overheating: must open with safety notice overheating-stop"))
        #expect(problems.contains("overheating: STOP condition overheating lacks its card"))
        #expect(!problems.contains { $0.hasPrefix("low-oil-pressure:") })
    }

    @Test("Unknown notices and cards, and frequency rankings, are reported")
    func unknownReferencesAndRankings() {
        let symptoms = Self.symptoms().map { s in
            s.id == "not-charging"
                ? Symptom(id: s.id, title: s.title, summary: "The most common cause is the belt.",
                          safetyNoticeIds: ["nope"], stopCardIds: ["gone"],
                          possibleCauses: [FaultCause(title: "Belt", detail: "Less common: the regulator.")],
                          checkFirst: s.checkFirst, lessonIds: s.lessonIds, reviewStatus: .draft)
                : s
        }
        let guide = FaultGuide(intro: "Most likely first.", reminder: "R", stopCards: Self.cards(), symptoms: symptoms)
        let problems = ContentLoader.validate(guide, lessonIDs: ["m01-l01"], noticeIDs: Self.noticeIDs)
        #expect(problems.contains("not-charging: unknown safety notice nope"))
        #expect(problems.contains("not-charging: unknown stop card gone"))
        #expect(problems.contains("not-charging: ranks causes with \"most common\""))
        #expect(problems.contains("not-charging: ranks causes with \"less common\""))
        #expect(problems.contains("faults: ranks causes with \"most likely\""))
    }

    @Test("Missing symptoms, duplicates, empty lists and an empty reminder are reported")
    func structuralRules() {
        let symptom = Symptom(id: "exhaust-smoke", title: "T", summary: "S", possibleCauses: [], checkFirst: [],
                              lessonIds: ["m01-l01", "m01-l01"], reviewStatus: .draft)
        let guide = FaultGuide(intro: "", reminder: " ", stopCards: Self.cards(), symptoms: [symptom, symptom])
        let problems = ContentLoader.validate(guide, lessonIDs: ["m01-l01"], noticeIDs: Self.noticeIDs)
        #expect(problems.contains("faults: reminder is empty"))
        #expect(problems.contains("faults: duplicate symptom id exhaust-smoke"))
        #expect(problems.contains("exhaust-smoke: has no possible causes"))
        #expect(problems.contains("exhaust-smoke: has nothing to check first"))
        #expect(problems.contains("exhaust-smoke: links to the same lesson twice"))
        #expect(problems.contains("faults: missing symptom wont-start"))
        #expect(!problems.contains("faults: missing symptom exhaust-smoke"))
    }

    // MARK: Helpers

    static let noticeIDs = Set(SafetyGuide.requiredNoticeIDs)

    static func cards() -> [StopCard] {
        FaultGuide.requiredStopCardIDs.map { StopCard(id: $0, title: $0, stop: "S", doNotRestart: "D", getAssistance: "A") }
    }

    static func symptoms() -> [Symptom] {
        FaultGuide.requiredSymptomIDs.sorted().map { id in
            let required = FaultGuide.requiredSymptomSafety[id]
            return Symptom(id: id, title: id, summary: "S",
                           safetyNoticeIds: required.map { [$0.noticeID] },
                           stopCardIds: required.map { [$0.stopCardID] },
                           possibleCauses: [FaultCause(title: "C", detail: "D")], checkFirst: ["Check"],
                           lessonIds: ["m01-l01"], reviewStatus: .draft)
        }
    }

    private static let moduleJSON = """
    {"id":"m01","number":1,"title":"T","summary":"S",
     "lessons":[{"id":"m01-l01","title":"L","estimatedMinutes":5,"intro":"I","diagram":null,
       "steps":[{"title":null,"text":"Step"}],"caution":null,"handsOn":false,"reviewStatus":"draft"}],
     "questions":[]}
    """

    static let safetyJSON: String = {
        let notices = SafetyGuide.requiredNoticeIDs.map { #"{"id":"\#($0)","level":"stop","title":"T","text":"Text"}"# }
        return #"{"notices":["# + notices.joined(separator: ",") + #"],"actionLevels":[{"id":"observe","label":"Observe","description":"D"},{"id":"owner","label":"Owner","description":"D"},{"id":"engineer","label":"Engineer only","description":"D"}],"tags":[{"id":"common-rail","group":"Fuel injection","label":"Common rail"}]}"#
    }()

    private static func loader(faults: String) -> ContentLoader {
        ContentLoader.inMemory([
            "manifest.json": #"{"schemaVersion":2,"modules":["a.json"],"faults":"faults.json","safety":"safety.json"}"#,
            "modules/a.json": moduleJSON,
            "faults.json": faults,
            "safety.json": safetyJSON,
        ])
    }

    /// Six valid symptoms and seven stop cards; the first symptom uses `lessonIds`.
    private static func faultsJSON(lessonIds: String = #"["m01-l01"]"#) -> String {
        let ids = ["exhaust-smoke", "wont-start", "overheating", "stops-suddenly", "low-oil-pressure", "not-charging"]
        let symptoms = ids.enumerated().map { index, id in
            var safety = ""
            if let required = FaultGuide.requiredSymptomSafety[id] {
                safety = #""safetyNoticeIds":["\#(required.noticeID)"],"stopCardIds":["\#(required.stopCardID)"],"#
            }
            return """
            {"id":"\(id)","title":"\(id)","summary":"S",\(safety)
             "possibleCauses":[{"title":"Cause 1","detail":"Detail"}],"checkFirst":["Check"],
             "lessonIds":\(index == 0 ? lessonIds : #"["m01-l01"]"#),"reviewStatus":"draft"}
            """
        }
        let cards = FaultGuide.requiredStopCardIDs.map {
            #"{"id":"\#($0)","title":"T","stop":"S","doNotRestart":"D","getAssistance":"A"}"#
        }
        return #"{"intro":"I","reminder":"Follow the handbook.","stopCards":["# + cards.joined(separator: ",")
            + #"],"symptoms":["# + symptoms.joined(separator: ",") + "]}"
    }
}
