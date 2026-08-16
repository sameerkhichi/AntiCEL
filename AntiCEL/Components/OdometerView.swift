import SwiftUI

struct OdometerView: View {

    @Environment(\.appTheme) private var theme
    @Environment(AppSettings.self) private var settings

    let mileage: Int
    var digitCount: Int = 6
    var compact: Bool = false

    private var displayMileage: Int {
        settings.mileageUnit.displayValue(fromStoredKilometers: mileage)
    }

    var body: some View {
        digitCluster
            .overlay(alignment: .trailing) {
                Text(settings.mileageUnit.abbreviation)
                    .font(.appBadge)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                    .offset(x: compact ? 22 : 26)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(displayMileage.formatted()) \(settings.mileageUnit.accessibilityName)")
    }

    private var digitCluster: some View {
        HStack(spacing: compact ? 1.5 : 2.5) {
            ForEach(Array(paddedDigits.enumerated()), id: \.offset) { _, character in
                digitWindow(character)
            }
        }
        .padding(.horizontal, compact ? 4 : 6)
        .padding(.vertical, compact ? 4 : 5)
        .background {
            RoundedRectangle(cornerRadius: compact ? 6 : 8, style: .continuous)
                .fill(housing)
                .overlay {
                    RoundedRectangle(cornerRadius: compact ? 6 : 8, style: .continuous)
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
    }

    private var paddedDigits: [Character] {
        let raw = String(max(displayMileage, 0))
        let pad = String(repeating: "0", count: max(digitCount - raw.count, 0))
        return Array((pad + raw).suffix(digitCount))
    }

    private var housing: Color {
        theme.isDark
            ? Color(red: 0.10, green: 0.10, blue: 0.11)
            : Color(red: 0.22, green: 0.22, blue: 0.23)
    }

    private var windowFill: Color {
        Color(red: 0.07, green: 0.07, blue: 0.075)
    }

    private func digitWindow(_ character: Character) -> some View {
        let size: CGFloat = compact ? 13 : 18
        let width: CGFloat = compact ? 13 : 18
        let height: CGFloat = compact ? 22 : 28

        return Text(String(character))
            .font(.system(size: size, weight: .medium, design: .monospaced))
            .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.90))
            .frame(width: width, height: height)
            .background {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.85),
                                windowFill,
                                Color.black.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    }
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                            .padding(.horizontal, 1)
                    }
            }
    }
}
