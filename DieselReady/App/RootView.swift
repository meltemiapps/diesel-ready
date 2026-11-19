import SwiftUI

/// Shows the first-launch disclaimer until the current version is accepted,
/// then the main tab bar.
struct RootView: View {
    @AppStorage(Disclaimer.acceptedVersionKey) private var acceptedVersion = 0

    var body: some View {
        Group {
            if Disclaimer.isAccepted(storedVersion: acceptedVersion) {
                MainTabView()
                    .transition(.opacity)
            } else {
                DisclaimerView {
                    acceptedVersion = Disclaimer.currentVersion
                }
                .transition(.opacity)
            }
        }
        .animation(.default, value: acceptedVersion)
        .tint(Theme.Palette.tint)
    }
}

struct MainTabView: View {
    enum Tab: Hashable {
        case learn, quiz, faults, about
    }

    @State private var selection: Tab = .learn

    var body: some View {
        TabView(selection: $selection) {
            LearnView()
                .tabItem { Label("Learn", systemImage: "book") }
                .tag(Tab.learn)
            QuizHomeView()
                .tabItem { Label("Quiz", systemImage: "checklist") }
                .tag(Tab.quiz)
            FaultsView()
                .tabItem { Label("Faults", systemImage: "wrench.and.screwdriver") }
                .tag(Tab.faults)
            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(Tab.about)
        }
    }
}

#Preview {
    RootView()
        .environment(ContentStore())
        .modelContainer(for: ProgressSchema.models, inMemory: true)
}
