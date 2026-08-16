import SwiftUI

struct AccentSwatchPicker: View {

    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let previewScheme: ColorScheme
    @Binding var selection: AccentOption

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            InfotainmentSectionHeader(title: title)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 72), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(AccentOption.allCases) { option in
                    let selected = selection == option

                    Button {
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
        }
    }
}
