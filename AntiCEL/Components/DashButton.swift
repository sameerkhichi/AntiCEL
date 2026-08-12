import SwiftUI

enum DashButtonKind {
    case key
    case bar
    case compact
}

struct DashButtonStyle: ButtonStyle {

    var isSelected = false
    var kind: DashButtonKind = .key
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        DashButtonChrome(
            isPressed: configuration.isPressed,
            isSelected: isSelected,
            kind: kind,
            isDestructive: isDestructive
        ) {
            configuration.label
        }
    }
}

private struct DashButtonChrome<Label: View>: View {

    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    let isPressed: Bool
    let isSelected: Bool
    let kind: DashButtonKind
    var isDestructive = false
    @ViewBuilder var label: () -> Label

    var body: some View {
        let scale: CGFloat = (isPressed && !reduceMotion) ? 0.96 : 1.0
        let face = isSelected ? theme.keyFaceSelected : theme.keyFace
        let radius: CGFloat = kind == .key ? 12 : 10

        label()
            .font(kind == .bar ? .headline : .subheadline.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: kind == .compact ? nil : .infinity)
            .padding(.horizontal, kind == .compact ? 12 : 10)
            .padding(.vertical, kind == .bar ? 14 : kind == .compact ? 8 : 6)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(face)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(theme.highlight, lineWidth: 1)
                            .padding(.bottom, 8)
                            .clipped()
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(theme.edge, lineWidth: 1)
                    }
                    .shadow(
                        color: isSelected ? Color.accentColor.opacity(0.45) : theme.shadow,
                        radius: isSelected ? 8 : 4,
                        y: isPressed ? 1 : 3
                    )
            }
            .scaleEffect(scale)
            .offset(y: isPressed ? 1 : 0)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isPressed)
    }

    private var foreground: Color {
        if isDestructive {
            return .red
        }
        if isSelected {
            return Color.accentColor
        }
        return Color.primary.opacity(0.9)
    }
}

struct DashButton<Label: View>: View {

    var isSelected = false
    var kind: DashButtonKind = .key
    var isDestructive = false
    let action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
        }
        .buttonStyle(DashButtonStyle(isSelected: isSelected, kind: kind, isDestructive: isDestructive))
    }
}

struct DashLED: View {

    var isOn: Bool

    var body: some View {
        Circle()
            .fill(isOn ? Color.accentColor : Color.primary.opacity(0.18))
            .frame(width: 5, height: 5)
            .shadow(color: isOn ? Color.accentColor.opacity(0.95) : .clear, radius: 4)
    }
}
