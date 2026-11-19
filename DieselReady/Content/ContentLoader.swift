import Foundation

/// Decodes and validates the bundled JSON content.
///
/// Pure and synchronous so it can be unit-tested with in-memory data.
struct ContentLoader: Sendable {
    /// Highest manifest schema version this build understands.
    static let supportedSchemaVersion = 1
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
        let library = ContentLibrary(schemaVersion: manifest.schemaVersion, modules: modules, faults: faults)

        let problems = Self.validate(library)
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
    static func validate(_ library: ContentLibrary) -> [String] {
        var problems: [String] = []
        var seenIDs = Set<String>()

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
            }

            let lessonIDs = Set(module.lessons.map(\.id))
            for lesson in module.lessons {
                checkUnique(lesson.id)
                if lesson.steps.isEmpty { problems.append("\(lesson.id): has no steps") }
                if lesson.estimatedMinutes <= 0 { problems.append("\(lesson.id): estimatedMinutes must be positive") }
                if let diagram = lesson.diagram,
                   let expected = Diagram.expectedLabelCounts[diagram.kind],
                   diagram.labels.count != expected {
                    problems.append("\(lesson.id): diagram \(diagram.kind) has \(diagram.labels.count) labels, expected \(expected)")
                }
            }

            for question in module.questions {
                checkUnique(question.id)
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
            }
        }

        if let faults = library.faults {
            problems += validate(faults, lessonIDs: Set(library.allLessons.map(\.id)))
        }
        return problems
    }

    /// Fault finder checks, including that every lesson link resolves.
    static func validate(_ faults: FaultGuide, lessonIDs: Set<Lesson.ID>) -> [String] {
        var problems: [String] = []
        var seen = Set<String>()

        if faults.reminder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("faults: reminder is empty")
        }
        for symptom in faults.symptoms {
            let id = symptom.id
            if !seen.insert(id).inserted { problems.append("faults: duplicate symptom id \(id)") }
            if symptom.causes.isEmpty { problems.append("\(id): has no causes") }
            if symptom.checkFirst.isEmpty { problems.append("\(id): has nothing to check first") }
            if symptom.lessonIds.isEmpty { problems.append("\(id): links to no lessons") }
            for lessonID in symptom.lessonIds where !lessonIDs.contains(lessonID) {
                problems.append("\(id): links to unknown lesson \(lessonID)")
            }
            if Set(symptom.lessonIds).count != symptom.lessonIds.count {
                problems.append("\(id): links to the same lesson twice")
            }
            if FaultGuide.stopFirstSymptomIDs.contains(id) {
                if let stop = symptom.stopFirst {
                    if stop.title != FaultGuide.stopFirstTitle {
                        problems.append("\(id): stopFirst title must be \"\(FaultGuide.stopFirstTitle)\"")
                    }
                    if stop.text.isEmpty { problems.append("\(id): stopFirst text is empty") }
                } else {
                    problems.append("\(id): must start with a stopFirst instruction")
                }
            }
        }
        for missing in FaultGuide.requiredSymptomIDs.subtracting(seen).sorted() {
            problems.append("faults: missing symptom \(missing)")
        }
        return problems
    }
}
