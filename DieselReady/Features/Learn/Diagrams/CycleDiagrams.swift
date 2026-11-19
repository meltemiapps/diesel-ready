import SwiftUI

// Panel text comes from the lesson JSON; these views only draw the shapes.
// LessonDiagram guarantees the label count before creating them.

/// Three panels: air drawn in, air compressed and heated, fuel sprayed in and ignites.
struct CompressionIgnitionDiagram: View {
    let labels: [DiagramLabel]

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s) {
            DiagramPanel(label: labels[0]) {
                CylinderSketch(pistonHeight: 0.05, inletOpen: true, gas: .air, motion: .bottom)
            }
            DiagramPanel(label: labels[1]) {
                CylinderSketch(pistonHeight: 0.92, gas: .hotAir, motion: .top)
            }
            DiagramPanel(label: labels[2]) {
                CylinderSketch(pistonHeight: 0.95, gas: .burning, showSpray: true)
            }
        }
    }
}

/// Four panels showing each stroke with valve positions and piston direction.
struct FourStrokeDiagram: View {
    let labels: [DiagramLabel]

    private let columns = [GridItem(.flexible(), spacing: Theme.Spacing.m, alignment: .top),
                           GridItem(.flexible(), spacing: Theme.Spacing.m, alignment: .top)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.l) {
            DiagramPanel(label: labels[0]) {
                CylinderSketch(pistonHeight: 0.1, inletOpen: true, gas: .air, motion: .bottom)
            }
            DiagramPanel(label: labels[1]) {
                CylinderSketch(pistonHeight: 0.9, gas: .hotAir, showSpray: true, motion: .top)
            }
            DiagramPanel(label: labels[2]) {
                CylinderSketch(pistonHeight: 0.15, gas: .burning, motion: .bottom)
            }
            DiagramPanel(label: labels[3]) {
                CylinderSketch(pistonHeight: 0.85, exhaustOpen: true, gas: .exhaust, motion: .top)
            }
        }
    }
}
