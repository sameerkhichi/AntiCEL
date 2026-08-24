import SwiftUI

struct ModelLoadingOdometer: View {

    @Environment(\.appTheme) private var theme

    var progress: Double

    private var clamped: Double {
        min(max(progress, 0), 100)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("LOADING")
                .font(.appBadge)
                .tracking(2.2)
                .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 4) {
                HStack(spacing: 3) {
                    RollingDigitDrum(value: clamped / 100)
                    RollingDigitDrum(value: clamped / 10)
                    RollingDigitDrum(value: clamped)
                }

                Text("%")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.90).opacity(0.72))
                    .padding(.leading, 2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(housing)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading vehicle model, \(Int(clamped.rounded())) percent")
    }

    private var housing: Color {
        theme.isDark
            ? Color(red: 0.10, green: 0.10, blue: 0.11)
            : Color(red: 0.22, green: 0.22, blue: 0.23)
    }

    static func progress(elapsed: TimeInterval) -> Double {
        let cruise: TimeInterval = 1.35
        if elapsed < cruise {
            let t = elapsed / cruise
            let eased = 1 - pow(1 - t, 2.35)
            return eased * 86
        }

        let extra = elapsed - cruise
        return min(99.2, 86 + (1 - exp(-extra / 1.05)) * 13.2)
    }
}

private struct RollingDigitDrum: View {

    var value: Double

    private static let rowHeight: CGFloat = 24
    private static let visibleRows = 5
    private static let drumWidth: CGFloat = 32
    private static let leadingPad = 2
    private static let cycles = 12

    private var cream: Color {
        Color(red: 0.93, green: 0.93, blue: 0.90)
    }

    private var strip: [Int] {
        let core = (0..<(Self.cycles * 10)).map { $0 % 10 }
        return [8, 9] + core + [0, 1]
    }

    private var contentIndex: Double {
        Double(Self.leadingPad) + max(value, 0)
    }

    var body: some View {
        let height = Self.rowHeight
        let centerRow = Self.visibleRows / 2

        VStack(spacing: 0) {
            ForEach(Array(strip.enumerated()), id: \.offset) { index, digit in
                drumTile(digit, at: index)
                    .frame(height: height)
            }
        }
        .offset(y: -(contentIndex - Double(centerRow)) * height)
        .frame(width: Self.drumWidth, height: height * CGFloat(Self.visibleRows), alignment: .top)
        .background { drumCylinder }
        .overlay { cylinderShading }
        .overlay { centerWindow }
        .overlay { edgeVignette }
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.45), radius: 3, y: 2)
        .allowsHitTesting(false)
    }

    private func drumTile(_ digit: Int, at index: Int) -> some View {
        let distance = abs(Double(index) - contentIndex)
        let selected = distance < 0.5
        let near = distance < 1.5

        return VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1)

            Text("\(digit)")
                .font(.system(size: selected ? 18 : 14, weight: .medium, design: .monospaced))
                .foregroundStyle(cream.opacity(selected ? 1 : near ? 0.38 : 0.16))
                .shadow(color: selected ? cream.opacity(0.25) : .clear, radius: 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var drumCylinder: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.94),
                Color(red: 0.14, green: 0.14, blue: 0.15),
                Color(red: 0.09, green: 0.09, blue: 0.10),
                Color.black.opacity(0.94)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var cylinderShading: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [Color.black.opacity(0.55), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 7)

            Spacer(minLength: 0)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.55)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 7)
        }
        .allowsHitTesting(false)
    }

    private var centerWindow: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.6)
            .background {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(height: 1)
                    .padding(.horizontal, 2)
            }
            .frame(height: Self.rowHeight)
            .padding(.horizontal, 3)
            .allowsHitTesting(false)
    }

    private var edgeVignette: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.black.opacity(0.82), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Self.rowHeight * 1.5)

            Spacer(minLength: 0)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Self.rowHeight * 1.5)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var startedAt = Date()

        var body: some View {
            TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                ModelLoadingOdometer(
                    progress: ModelLoadingOdometer.progress(
                        elapsed: context.date.timeIntervalSince(startedAt)
                    )
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appCanvas()
        }
    }

    return PreviewHost()
        .appTheme()
}
