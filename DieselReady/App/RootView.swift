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
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selectedTab) {
            LearnView()
                .tabItem { Label("Learn", systemImage: "book") }
                .tag(AppNavigation.Tab.learn)
            QuizHomeView()
                .tabItem { Label("Quiz", systemImage: "questionmark.circle") }
                .tag(AppNavigation.Tab.quiz)
            ChecksView()
                .tabItem { Label("Checks", systemImage: "checklist") }
                .tag(AppNavigation.Tab.checks)
            FaultsView()
                .tabItem { Label("Faults", systemImage: "wrench.and.screwdriver") }
                .tag(AppNavigation.Tab.faults)
            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(AppNavigation.Tab.about)
        }
    }
}

#Preview {
    RootView()
        .environment(ContentStore())
        .environment(AppNavigation())
        .modelContainer(for: ProgressSchema.models, inMemory: true)
}
