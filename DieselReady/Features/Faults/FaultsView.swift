import SwiftUI

/// Fault finder tab placeholder. Built in Phase 4.
struct FaultsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Fault finder", systemImage: "wrench.and.screwdriver")
            } description: {
                Text("Pick a symptom to see likely causes and what to check first. Coming in a later build.")
            }
            .background(Theme.Palette.background)
            .navigationTitle("Faults")
        }
    }
}
