import SwiftUI

struct MileageDigitScroller: View {

    @Environment(\.appTheme) private var theme

    @Binding var mileage: Int
    var digitCount: Int = 6

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<digitCount, id: \.self) { index in
                digitWheel(at: index)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
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
        .colorScheme(.dark)
        .overlay(alignment: .trailing) {
            Text("km")
                .font(.appBadge)
                .tracking(1.2)
                .foregroundStyle(.secondary)
                .colorScheme(theme.isDark ? .dark : .light)
                .offset(x: 26)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mileage digits")
    }

    private func digitWheel(at index: Int) -> some View {
        Picker(placeName(at: index), selection: digitBinding(at: index)) {
            ForEach(0..<10, id: \.self) { value in
                Text("\(value)")
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.90))
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(width: 44, height: 132)
        .clipped()
        .accessibilityLabel(placeName(at: index))
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

    private var housing: Color {
        theme.isDark
            ? Color(red: 0.10, green: 0.10, blue: 0.11)
            : Color(red: 0.22, green: 0.22, blue: 0.23)
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

#Preview {
    struct PreviewHost: View {
        @State private var mileage = 79500

        var body: some View {
            MileageDigitScroller(mileage: $mileage)
                .padding()
        }
    }

    return PreviewHost()
        .appTheme()
}
