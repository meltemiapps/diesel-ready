import Foundation
import Testing
@testable import DieselReady

@Suite("Fault finder content")
struct FaultContentTests {

    // MARK: Bundled content

    @Test("Bundled fault content decodes with all six symptoms")
    func bundledFaultsDecode() throws {
        let library = try ContentLoader.bundled(.main).load()
        let guide = try #require(library.faults)
        #expect(Set(guide.symptoms.map(\.id)) == FaultGuide.requiredSymptomIDs)
        #expect(guide.symptoms.map(\.title) == [
            "Exhaust smoke", "Won't start", "Overheating", "Stops suddenly", "Low oil pressure", "Not charging",
        ])
        #expect(guide.symptoms.allSatisfy { $0.reviewStatus == .draft })
        #expect(guide.symptoms.allSatisfy { !$0.causes.isEmpty && !$0.checkFirst.isEmpty && !$0.lessonIds.isEmpty })
    }

    @Test("Engine-damaging symptoms open with Stop the engine; the others do not")
    func stopFirst() throws {
        let guide = try #require(try ContentLoader.bundled(.main).load().faults)
        for symptom in guide.symptoms {
            if FaultGuide.stopFirstSymptomIDs.contains(symptom.id) {
                let stop = try #require(symptom.stopFirst, "\(symptom.id) needs a stop instruction")
                #expect(stop.title == "Stop the engine")
                #expect(stop.text.hasPrefix("Stop the engine"), "\(symptom.id) text should open with the instruction")
            } else {
                #expect(symptom.stopFirst == nil, "\(symptom.id) should not open with a stop instruction")
            }
        }
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

    @Test("Fault JSON decodes, including a null stopFirst")
    func decodesFromJSON() throws {
        let library = try Self.loader(faults: Self.faultsJSON()).load()
        let guide = try #require(library.faults)
        #expect(guide.symptoms.count == 6)
        let overheating = try #require(guide.symptom(withID: "overheating"))
        #expect(overheating.stopFirst?.title == "Stop the engine")
        #expect(overheating.causes.first == FaultCause(title: "Cause 1", detail: "Detail"))
        #expect(overheating.checkFirst == ["Check"])
        #expect(guide.symptom(withID: "wont-start")?.stopFirst == nil)
    }

    @Test("A manifest without a faults entry loads with no fault guide")
    func faultsAreOptionalInManifest() throws {
        let loader = ContentLoader.inMemory([
            "manifest.json": #"{"schemaVersion":1,"modules":["a.json"]}"#,
            "modules/a.json": Self.moduleJSON,
        ])
        #expect(try loader.load().faults == nil)
    }

    @Test("A missing faults file is reported by name")
    func missingFaultsFile() {
        let loader = ContentLoader.inMemory([
            "manifest.json": #"{"schemaVersion":1,"modules":["a.json"],"faults":"faults.json"}"#,
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

    @Test("Missing or mis-titled stop instructions are reported")
    func stopInstructionRules() {
        let missing = Self.guide { id in id == "overheating" ? nil : Self.stop(for: id) }
        #expect(ContentLoader.validate(missing, lessonIDs: ["m01-l01"])
            .contains("overheating: must start with a stopFirst instruction"))

        let wrongTitle = Self.guide { id in
            FaultGuide.stopFirstSymptomIDs.contains(id) ? StopInstruction(title: "Be careful", text: "x") : nil
        }
        let problems = ContentLoader.validate(wrongTitle, lessonIDs: ["m01-l01"])
        #expect(problems.contains { $0.hasPrefix("low-oil-pressure: stopFirst title") })
        #expect(problems.contains { $0.hasPrefix("overheating: stopFirst title") })
    }

    @Test("Missing symptoms, duplicates, empty lists and an empty reminder are reported")
    func structuralRules() {
        let symptom = Symptom(id: "overheating", title: "T", summary: "S", stopFirst: nil,
                              causes: [], checkFirst: [], lessonIds: ["m01-l01", "m01-l01"], reviewStatus: .draft)
        let guide = FaultGuide(intro: "", reminder: " ", symptoms: [symptom, symptom])
        let problems = ContentLoader.validate(guide, lessonIDs: ["m01-l01"])
        #expect(problems.contains("faults: reminder is empty"))
        #expect(problems.contains("faults: duplicate symptom id overheating"))
        #expect(problems.contains("overheating: has no causes"))
        #expect(problems.contains("overheating: has nothing to check first"))
        #expect(problems.contains("overheating: links to the same lesson twice"))
        #expect(problems.contains("faults: missing symptom wont-start"))
        #expect(!problems.contains("faults: missing symptom overheating"))
    }

    // MARK: Helpers

    private static let moduleJSON = """
    {"id":"m01","number":1,"title":"T","summary":"S",
     "lessons":[{"id":"m01-l01","title":"L","estimatedMinutes":5,"intro":"I","diagram":null,
       "steps":[{"title":null,"text":"Step"}],"caution":null,"handsOn":false,"reviewStatus":"draft"}],
     "questions":[]}
    """

    private static func loader(faults: String) -> ContentLoader {
        ContentLoader.inMemory([
            "manifest.json": #"{"schemaVersion":1,"modules":["a.json"],"faults":"faults.json"}"#,
            "modules/a.json": moduleJSON,
            "faults.json": faults,
        ])
    }

    /// Six valid symptoms; the first uses `lessonIds`.
    private static func faultsJSON(lessonIds: String = #"["m01-l01"]"#) -> String {
        let ids = ["exhaust-smoke", "wont-start", "overheating", "stops-suddenly", "low-oil-pressure", "not-charging"]
        let symptoms = ids.enumerated().map { index, id in
            let stop = FaultGuide.stopFirstSymptomIDs.contains(id)
                ? #"{"title":"Stop the engine","text":"Stop it now."}"#
                : "null"
            return """
            {"id":"\(id)","title":"\(id)","summary":"S","stopFirst":\(stop),
             "causes":[{"title":"Cause 1","detail":"Detail"}],"checkFirst":["Check"],
             "lessonIds":\(index == 0 ? lessonIds : #"["m01-l01"]"#),"reviewStatus":"draft"}
            """
        }
        return #"{"intro":"I","reminder":"Follow the handbook.","symptoms":["# + symptoms.joined(separator: ",") + "]}"
    }

    private static func stop(for id: String) -> StopInstruction? {
        FaultGuide.stopFirstSymptomIDs.contains(id) ? StopInstruction(title: "Stop the engine", text: "Stop.") : nil
    }

    private static func guide(stop: (String) -> StopInstruction?) -> FaultGuide {
        let symptoms = FaultGuide.requiredSymptomIDs.sorted().map { id in
            Symptom(id: id, title: id, summary: "S", stopFirst: stop(id),
                    causes: [FaultCause(title: "C", detail: "D")], checkFirst: ["Check"],
                    lessonIds: ["m01-l01"], reviewStatus: .draft)
        }
        return FaultGuide(intro: "I", reminder: "R", symptoms: symptoms)
    }
}
