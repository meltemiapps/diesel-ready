import SwiftUI

/// A numbered sequence of stages joined by arrows, used for circuits such as
/// the fuel path or the raw water circuit. Text comes from the JSON labels.
struct FlowDiagram: View {
    let labels: [DiagramLabel]

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                    Text("\(index + 1)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.Palette.onHero)
                        .frame(minWidth: 28, minHeight: 28)
                        .background(Circle().fill(Theme.Palette.deepBlue))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label.title)
                            .font(.headline)
                            .foregroundStyle(Theme.Palette.ink)
                        if let detail = label.detail {
                            Text(detail)
                                .font(.footnote)
                                .foregroundStyle(Theme.Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Theme.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                        .fill(Theme.Palette.background)
                )
                if index < labels.count - 1 {
                    Image(systemName: "arrow.down")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.Palette.link)
                }
            }
        }
    }
}
