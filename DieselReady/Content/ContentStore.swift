import Foundation
import Observation

/// App-wide access to the decoded content. Created once at launch and passed
/// through the SwiftUI environment.
@MainActor
@Observable
final class ContentStore {
    private(set) var library: ContentLibrary
    /// Set when the bundled content could not be loaded. Shown in place of
    /// the module list so a broken content file is obvious during development.
    private(set) var loadError: String?

    init(loader: ContentLoader = .bundled()) {
        do {
            library = try loader.load()
            loadError = nil
        } catch {
            library = .empty
            loadError = String(describing: error)
        }
    }

    var modules: [Module] { library.modules }
}
