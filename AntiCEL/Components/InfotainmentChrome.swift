import SwiftUI

struct InfotainmentScaffold<Content: View>: View {

    @Environment(\.appTheme) private var theme

    let title: String
    var confirmTitle: String = "Save"
    var confirmEnabled: Bool = true
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    content()
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .background(theme.infotainment.ignoresSafeArea())
        .presentationBackground(theme.infotainment)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 12) {
            DashButton(kind: .compact, action: onCancel) {
                Text("Cancel")
            }

            Spacer(minLength: 8)

            Text(title)
                .font(.headline.width(.condensed))
                .tracking(0.8)
                .lineLimit(1)

            Spacer(minLength: 8)

            DashButton(isSelected: confirmEnabled, kind: .compact, action: onConfirm) {
                Text(confirmTitle)
            }
            .disabled(!confirmEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(theme.housing.opacity(0.92))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.edge)
                .frame(height: 1)
        }
    }
}

struct InfotainmentSectionHeader: View {

    let title: String

    var body: some View {
        Text(title)
            .font(.appBadge)
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }
}

struct InfotainmentField<Content: View>: View {

    @Environment(\.appTheme) private var theme

    var label: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label {
                InfotainmentSectionHeader(title: label)
            }

            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.panel)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [theme.highlight, theme.edge],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                }
        }
    }
}

struct InfotainmentChipPicker<Option: Hashable>: View {

    @Environment(\.appTheme) private var theme

    let title: String
    @Binding var selection: Option
    let options: [Option]
    let itemTitle: (Option) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InfotainmentSectionHeader(title: title)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(options, id: \.self) { option in
                    let selected = selection == option

                    Button {
                        selection = option
                    } label: {
                        Text(itemTitle(option))
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selected ? theme.keyFaceSelected : theme.keyFace)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(
                                                selected
                                                    ? Color.accentColor.opacity(0.75)
                                                    : theme.edge,
                                                lineWidth: 1
                                            )
                                    }
                                    .shadow(
                                        color: selected ? Color.accentColor.opacity(0.35) : .clear,
                                        radius: 5
                                    )
                            }
                            .foregroundStyle(selected ? Color.accentColor : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
