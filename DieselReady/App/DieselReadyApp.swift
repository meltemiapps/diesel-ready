import SwiftData
import SwiftUI

@main
struct DieselReadyApp: App {
    @State private var content = ContentStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(content)
        }
        .modelContainer(for: ProgressSchema.models)
    }
}
