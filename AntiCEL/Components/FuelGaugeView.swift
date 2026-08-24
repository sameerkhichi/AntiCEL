import SwiftUI

struct FuelGaugeView: View {

    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let percent: Double

    private let diameter: CGFloat = 118

    private var clamped: Double {
        min(max(percent, 0), 100)
    }

    private var isLow: Bool {
        clamped <= 15
    }

    private var needleAngle: Angle {
        Angle.degrees(-90 + clamped / 100 * 180)
    }

    private var needleColor: Color {
        isLow ? Color(red: 0.92, green: 0.22, blue: 0.18) : Color(red: 0.93, green: 0.93, blue: 0.90)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(housing)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [theme.highlight.opacity(0.55), theme.edge],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: .black.opacity(theme.isDark ? 0.5 : 0.18), radius: 3, y: 2)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.12, green: 0.12, blue: 0.13),
                            Color(red: 0.06, green: 0.06, blue: 0.07)
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: diameter * 0.48
                    )
                )
                .padding(7)
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.8)
                        .padding(7)
                }

            ticks
            labels

            GaugeArc(startPercent: 0, endPercent: 100)
                .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 3.5, lineCap: .butt))
                .padding(18)

            GaugeArc(startPercent: 0, endPercent: 15)
                .stroke(
                    Color(red: 0.86, green: 0.18, blue: 0.16).opacity(0.9),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .butt)
                )
                .padding(18)

            needle
                .rotationEffect(needleAngle)
                .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.72), value: clamped)

            hub

            VStack(spacing: 1) {
                Text("\(Int(clamped.rounded()))%")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(needleColor)
                    .contentTransition(reduceMotion ? .identity : .numericText())

                Text("FUEL")
                    .font(.appBadge)
                    .tracking(1.6)
                    .foregroundStyle(Color.white.opacity(0.42))
            }
            .offset(y: 30)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fuel \(Int(clamped.rounded())) percent")
    }

    private var ticks: some View {
        ZStack {
            ForEach(0...10, id: \.self) { index in
                let major = index % 5 == 0
                Capsule(style: .continuous)
                    .fill(index <= 1 ? Color(red: 0.86, green: 0.18, blue: 0.16) : Color.white.opacity(major ? 0.72 : 0.28))
                    .frame(width: major ? 2.2 : 1.1, height: major ? 11 : 6)
                    .offset(y: -(diameter * 0.38))
                    .rotationEffect(tickAngle(for: index))
            }
        }
    }

    private var labels: some View {
        ZStack {
            Text("E")
                .offset(x: -40, y: 2)
            Text("1/2")
                .offset(y: -44)
            Text("F")
                .offset(x: 40, y: 2)
        }
        .font(.system(size: 9, weight: .bold, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.7))
    }

    private var needle: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            var path = Path()
            path.move(to: CGPoint(x: center.x - 2.2, y: center.y + 8))
            path.addLine(to: CGPoint(x: center.x, y: 16))
            path.addLine(to: CGPoint(x: center.x + 2.2, y: center.y + 8))
            path.closeSubpath()
            context.fill(path, with: .color(needleColor))
        }
        .shadow(color: needleColor.opacity(0.45), radius: isLow ? 4 : 0)
    }

    private var hub: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.42, green: 0.42, blue: 0.44),
                        Color(red: 0.16, green: 0.16, blue: 0.17)
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 8
                )
            )
            .frame(width: 12, height: 12)
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.6)
            }
            .overlay {
                Circle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: 4, height: 4)
            }
    }

    private func tickAngle(for index: Int) -> Angle {
        Angle.degrees(-90 + Double(index) / 10 * 180)
    }

    private var housing: Color {
        theme.isDark
            ? Color(red: 0.10, green: 0.10, blue: 0.11)
            : Color(red: 0.22, green: 0.22, blue: 0.23)
    }
}

private struct GaugeArc: Shape {
    var startPercent: Double
    var endPercent: Double

    func path(in rect: CGRect) -> Path {
        let start = Angle.degrees(-180 + startPercent / 100 * 180)
        let end = Angle.degrees(-180 + endPercent / 100 * 180)
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: start,
            endAngle: end,
            clockwise: false
        )
        return path
    }
}
