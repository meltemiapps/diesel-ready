import SwiftUI

/// Draws a lesson diagram from its platform-neutral `kind`.
/// Returns nil for kinds this version does not know, so they are skipped.
struct LessonDiagram: View {
    private enum Kind: String {
        case compressionIgnition = "compression-ignition"
        case fourStrokeCycle = "four-stroke-cycle"
        case engineLayout = "engine-layout"
        case flow
    }

    private let kind: Kind
    private let diagram: Diagram

    /// Nil for unknown kinds, or if the label count does not match what the
    /// kind draws (the content validator also reports that case).
    init?(diagram: Diagram) {
        guard let kind = Kind(rawValue: diagram.kind),
              Diagram.labelCounts[diagram.kind]?.contains(diagram.labels.count) == true
        else { return nil }
        self.kind = kind
        self.diagram = diagram
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Group {
                switch kind {
                case .compressionIgnition: CompressionIgnitionDiagram(labels: diagram.labels)
                case .fourStrokeCycle: FourStrokeDiagram(labels: diagram.labels)
                case .engineLayout: EngineLayoutDiagram(labels: diagram.labels)
                case .flow: FlowDiagram(labels: diagram.labels)
                }
            }
            // Labels inside drawings cannot reflow, so cap their size; the
            // steps repeat the same information at full size, and VoiceOver
            // reads the description instead.
            .dynamicTypeSize(kind == .flow
                ? DynamicTypeSize.xSmall...DynamicTypeSize.accessibility5
                : DynamicTypeSize.xSmall...DynamicTypeSize.xLarge)
            .accessibilityHidden(true)
            if let caption = diagram.caption {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Diagram")
        .accessibilityValue(diagram.description)
    }
}

// MARK: - Shared cylinder drawing

/// A schematic cylinder: walls, head with inlet (left) and exhaust (right)
/// valves, a piston at a given height, and optional fuel spray or flame.
struct CylinderSketch: View {
    enum Gas { case none, air, hotAir, burning, exhaust }

    /// 0 = bottom of stroke, 1 = top of stroke.
    var pistonHeight: CGFloat
    var inletOpen = false
    var exhaustOpen = false
    var gas: Gas = .none
    var showSpray = false
    var motion: VerticalEdge? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let wall: CGFloat = 4
            let headH = h * 0.14
            let innerTop = headH
            let strokeTop = innerTop + h * 0.08
            let strokeBottom = h * 0.62
            let pistonH = h * 0.16
            let pistonY = strokeBottom - (strokeBottom - strokeTop) * pistonHeight
            let bore = w * 0.7
            let left = (w - bore) / 2

            ZStack(alignment: .topLeading) {
                // Gas above the piston.
                Rectangle()
                    .fill(gasColor)
                    .frame(width: bore, height: max(pistonY - innerTop, 0))
                    .offset(x: left, y: innerTop)

                // Cylinder walls.
                Rectangle().fill(Theme.Palette.secondaryText)
                    .frame(width: wall, height: h * 0.8 - innerTop)
                    .offset(x: left - wall, y: innerTop)
                Rectangle().fill(Theme.Palette.secondaryText)
                    .frame(width: wall, height: h * 0.8 - innerTop)
                    .offset(x: left + bore, y: innerTop)

                // Cylinder head.
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.Palette.deepBlue)
                    .frame(width: bore + wall * 2, height: headH)
                    .offset(x: left - wall, y: 0)

                // Valves: dropped into the cylinder when open.
                valve(open: inletOpen, x: left + bore * 0.18, top: headH, bore: bore)
                valve(open: exhaustOpen, x: left + bore * 0.62, top: headH, bore: bore)

                // Injector in the middle of the head.
                Rectangle()
                    .fill(Theme.Palette.accent)
                    .frame(width: 6, height: headH * 0.9)
                    .offset(x: w / 2 - 3, y: headH * 0.3)

                if showSpray {
                    SprayShape()
                        .fill(Theme.Palette.accent.opacity(0.85))
                        .frame(width: bore * 0.5, height: max(pistonY - innerTop, 8) * 0.8)
                        .offset(x: w / 2 - bore * 0.25, y: innerTop)
                }

                // Piston, connecting rod and crank pin.
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.Palette.link)
                    .frame(width: bore - 2, height: pistonH)
                    .offset(x: left + 1, y: pistonY)
                Rectangle()
                    .fill(Theme.Palette.secondaryText)
                    .frame(width: 6, height: h - (pistonY + pistonH) - h * 0.06)
                    .offset(x: w / 2 - 3, y: pistonY + pistonH)
                Circle()
                    .fill(Theme.Palette.secondaryText)
                    .frame(width: h * 0.1, height: h * 0.1)
                    .offset(x: w / 2 - h * 0.05, y: h * 0.88)

                if let motion {
                    Image(systemName: motion == .top ? "arrow.up" : "arrow.down")
                        .font(.system(size: max(h * 0.1, 12), weight: .bold))
                        .foregroundStyle(Theme.Palette.ink)
                        .position(x: w * 0.93, y: h * 0.45)
                }
            }
        }
        .aspectRatio(0.62, contentMode: .fit)
    }

    private var gasColor: Color {
        switch gas {
        case .none: .clear
        case .air: Theme.Palette.link.opacity(0.18)
        case .hotAir: Theme.Palette.accent.opacity(0.35)
        case .burning: Theme.Palette.error.opacity(0.45)
        case .exhaust: Theme.Palette.secondaryText.opacity(0.35)
        }
    }

    private func valve(open: Bool, x: CGFloat, top: CGFloat, bore: CGFloat) -> some View {
        let drop: CGFloat = open ? 8 : 0
        return VStack(spacing: 0) {
            Rectangle().fill(Theme.Palette.ink).frame(width: 3, height: 10 + drop)
            Capsule().fill(Theme.Palette.ink).frame(width: bore * 0.2, height: 4)
        }
        .frame(width: bore * 0.2)
        .offset(x: x, y: top - 10)
    }
}

/// A cone widening downwards from the injector tip.
private struct SprayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX - 2, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX + 2, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// A labelled panel: drawing above, short caption below.
struct DiagramPanel<Content: View>: View {
    let label: DiagramLabel
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            content
                .frame(maxWidth: 110)
            Text(label.title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.center)
            if let detail = label.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(Theme.Palette.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
