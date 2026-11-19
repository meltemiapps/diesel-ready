import SwiftUI

/// Simplified side view of a small marine diesel with numbered parts and a
/// legend underneath. Numbers rather than in-drawing labels keep it legible
/// at every Dynamic Type size.
struct EngineLayoutDiagram: View {
    /// Seven part names from the lesson JSON, matching markers 1 to 7.
    let labels: [DiagramLabel]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            drawing
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
            legend
        }
    }

    private var drawing: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bodyLeft = w * 0.18
            let bodyWidth = w * 0.62
            let headY = h * 0.08, headH = h * 0.16
            let blockY = headY + headH, blockH = h * 0.40
            let crankY = blockY + blockH
            let sumpY = crankY + h * 0.06, sumpH = h * 0.18

            ZStack(alignment: .topLeading) {
                // Sump
                UnevenRoundedRectangle(bottomLeadingRadius: 14, bottomTrailingRadius: 14)
                    .fill(Theme.Palette.secondaryText.opacity(0.35))
                    .frame(width: bodyWidth * 0.9, height: sumpH)
                    .offset(x: bodyLeft + bodyWidth * 0.05, y: sumpY)

                // Block with three pistons
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.Palette.link.opacity(0.25))
                    .frame(width: bodyWidth, height: blockH)
                    .offset(x: bodyLeft, y: blockY)
                ForEach(0..<3, id: \.self) { i in
                    let slot = bodyWidth / 3
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.Palette.link)
                        .frame(width: slot * 0.6, height: blockH * 0.28)
                        .offset(x: bodyLeft + slot * (CGFloat(i) + 0.2),
                                y: blockY + blockH * (i == 1 ? 0.2 : 0.45))
                }

                // Head
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.Palette.deepBlue)
                    .frame(width: bodyWidth, height: headH)
                    .offset(x: bodyLeft, y: headY)

                // Injectors on top of the head
                ForEach(0..<3, id: \.self) { i in
                    let slot = bodyWidth / 3
                    Rectangle()
                        .fill(Theme.Palette.accent)
                        .frame(width: 6, height: headY + headH * 0.4)
                        .offset(x: bodyLeft + slot * (CGFloat(i) + 0.5) - 3, y: 0)
                }

                // Crankshaft line
                Capsule()
                    .fill(Theme.Palette.ink)
                    .frame(width: bodyWidth * 1.12, height: 6)
                    .offset(x: bodyLeft, y: crankY)

                // Flywheel at the right-hand end
                Circle()
                    .strokeBorder(Theme.Palette.ink, lineWidth: 4)
                    .background(Circle().fill(Theme.Palette.surface))
                    .frame(width: h * 0.34, height: h * 0.34)
                    .offset(x: bodyLeft + bodyWidth * 1.04, y: crankY - h * 0.17)

                // Injection pump on the left side of the block
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.Palette.accent)
                    .frame(width: w * 0.12, height: blockH * 0.5)
                    .offset(x: bodyLeft - w * 0.14, y: blockY + blockH * 0.2)

                marker(1, x: bodyLeft + bodyWidth * 0.5, y: headY + headH * 0.5)
                marker(2, x: bodyLeft + bodyWidth / 6, y: headY * 0.45)
                marker(3, x: bodyLeft + bodyWidth * 0.5, y: blockY + blockH * 0.82)
                marker(4, x: bodyLeft + bodyWidth * 0.25, y: crankY + 2)
                marker(5, x: bodyLeft + bodyWidth * 0.5, y: sumpY + sumpH * 0.55)
                marker(6, x: bodyLeft + bodyWidth * 1.04 + h * 0.17, y: crankY)
                marker(7, x: bodyLeft - w * 0.08, y: blockY + blockH * 0.45)
            }
        }
        .aspectRatio(1.6, contentMode: .fit)
    }

    private func marker(_ number: Int, x: CGFloat, y: CGFloat) -> some View {
        Text("\(number)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(Theme.Palette.onAccent)
            .frame(width: 20, height: 20)
            .background(Circle().fill(Theme.Palette.surface))
            .overlay(Circle().strokeBorder(Theme.Palette.onAccent, lineWidth: 1.5))
            .position(x: x, y: y)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, part in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    Text("\(index + 1)")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.Palette.ink)
                        .frame(minWidth: 18, alignment: .trailing)
                    Text(part.title)
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.ink)
                }
            }
        }
    }
}
