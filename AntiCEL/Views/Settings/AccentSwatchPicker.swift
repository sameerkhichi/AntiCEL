import SwiftUI

struct AccentSwatchPicker: View {

    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let previewScheme: ColorScheme
    @Binding var selection: AccentOption

    @State private var isExpanded = false

    var body: some View {
        InfotainmentField {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    AppHaptic.button.play()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)

                            Text(selection.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 8)

                        Circle()
                            .fill(selection.color(for: previewScheme))
                            .frame(width: 22, height: 22)
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                            }
                            .shadow(
                                color: selection.color(for: previewScheme).opacity(0.4),
                                radius: 4
                            )

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityValue(selection.displayName)
                .accessibilityHint(isExpanded ? "Collapses color options" : "Shows color options")

                if isExpanded {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 72), spacing: 10)],
                        alignment: .leading,
                        spacing: 10
                    ) {
                        ForEach(AccentOption.allCases) { option in
                            swatchButton(option)
                        }
                    }
                }
            }
        }
    }

    private func swatchButton(_ option: AccentOption) -> some View {
        let selected = selection == option

        return Button {
            AppHaptic.button.play()
            selection = option
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(option.color(for: previewScheme))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    }
                    .shadow(
                        color: option.color(for: previewScheme).opacity(0.45),
                        radius: selected ? 6 : 0
                    )

                Text(option.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(selected ? Color.accentColor : Color.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? option.selectedKeyFace(for: colorScheme) : theme.keyFace)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                selected
                                    ? option.color(for: colorScheme).opacity(0.8)
                                    : theme.edge,
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}
