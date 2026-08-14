import SwiftUI

struct MileageDigitScroller: View {

    @Binding var mileage: Int
    var digitCount: Int = 6

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<digitCount, id: \.self) { index in
                MechanicalOdometerDrum(
                    digit: digitBinding(at: index),
                    placeName: placeName(at: index)
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mileage digits")
    }

    private func digitBinding(at index: Int) -> Binding<Int> {
        Binding(
            get: {
                paddedDigits[index]
            },
            set: { newDigit in
                var next = paddedDigits
                next[index] = newDigit
                mileage = Self.intValue(from: next)
            }
        )
    }

    private var paddedDigits: [Int] {
        Self.paddedDigits(from: mileage, count: digitCount)
    }

    private func placeName(at index: Int) -> String {
        let names = [
            "Hundred thousands",
            "Ten thousands",
            "Thousands",
            "Hundreds",
            "Tens",
            "Ones"
        ]
        let offset = names.count - digitCount
        if index + offset >= 0, index + offset < names.count {
            return names[index + offset]
        }
        return "Digit \(index + 1)"
    }

    static func paddedDigits(from mileage: Int, count: Int) -> [Int] {
        let raw = String(max(mileage, 0))
        let pad = String(repeating: "0", count: max(count - raw.count, 0))
        return Array((pad + raw).suffix(count)).compactMap { Int(String($0)) }
    }

    static func intValue(from digits: [Int]) -> Int {
        Int(digits.map(String.init).joined()) ?? 0
    }
}

private struct MechanicalOdometerDrum: View {

    @Binding var digit: Int
    let placeName: String

    @State private var position: Int?

    private static let rowHeight: CGFloat = 36
    private static let visibleRows = 5
    private static let drumWidth: CGFloat = 46

    private var cream: Color {
        Color(red: 0.93, green: 0.93, blue: 0.90)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { value in
                    drumTile(value)
                        .frame(height: Self.rowHeight)
                        .id(value)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $position, anchor: .center)
        .contentMargins(.vertical, Self.rowHeight * 2, for: .scrollContent)
        .frame(width: Self.drumWidth, height: Self.rowHeight * CGFloat(Self.visibleRows))
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
        .accessibilityLabel(placeName)
        .accessibilityValue("\(digit)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                digit = (digit + 1) % 10
            case .decrement:
                digit = (digit + 9) % 10
            default:
                break
            }
        }
        .onAppear {
            position = digit
        }
        .onChange(of: position) { _, newValue in
            if let newValue, newValue != digit {
                digit = newValue
            }
        }
        .onChange(of: digit) { _, newValue in
            if position != newValue {
                position = newValue
            }
        }
    }

    private func drumTile(_ value: Int) -> some View {
        let selected = value == digit

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

            Text("\(value)")
                .font(.system(size: selected ? 22 : 17, weight: .medium, design: .monospaced))
                .foregroundStyle(cream.opacity(selected ? 1 : 0.32))
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
            .frame(width: 9)

            Spacer(minLength: 0)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.55)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 9)
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
            .frame(height: Self.rowHeight * 1.6)

            Spacer(minLength: 0)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Self.rowHeight * 1.6)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var mileage = 79500

        var body: some View {
            MileageDigitScroller(mileage: $mileage)
                .padding()
                .appCanvas()
        }
    }

    return PreviewHost()
        .appTheme()
}
