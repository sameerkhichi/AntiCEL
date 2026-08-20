import SwiftUI

struct FuelGaugeView: View {

    @Environment(\.appTheme) private var theme

    let percent: Double

    private var clamped: Double {
        min(max(percent, 0), 100)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("FUEL")
                .font(.appBadge)
                .tracking(1.2)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.black.opacity(theme.isDark ? 0.55 : 0.28))

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(theme.accentColor)
                        .frame(width: max(geo.size.width * CGFloat(clamped / 100), 4))
                }
            }
            .frame(height: 8)

            Text("\(Int(clamped.rounded()))%")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.90))
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: 220)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(housing)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [theme.highlight.opacity(0.45), theme.edge],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(theme.isDark ? 0.5 : 0.18), radius: 3, y: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fuel \(Int(clamped.rounded())) percent")
    }

    private var housing: Color {
        theme.isDark
            ? Color(red: 0.10, green: 0.10, blue: 0.11)
            : Color(red: 0.22, green: 0.22, blue: 0.23)
    }
}
