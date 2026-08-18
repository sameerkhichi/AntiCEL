import SwiftUI

struct InfotainmentScaffold<Content: View>: View {

    @Environment(\.appTheme) private var theme

    let title: String
    var confirmTitle: String = "Save"
    var cancelTitle: String = "Cancel"
    var confirmEnabled: Bool = true
    var scrolls: Bool = true
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            header

            if scrolls {
                ScrollView {
                    contentStack
                }
            } else {
                contentStack
            }
        }
        .background(theme.infotainment.ignoresSafeArea())
        .presentationBackground(theme.infotainment)
        .tint(theme.accentColor)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 18) {
            content()
        }
        .padding(20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: scrolls ? nil : .infinity, alignment: .top)
    }

    private var header: some View {
        HStack(spacing: 12) {
            DashButton(kind: .compact, action: onCancel) {
                Text(cancelTitle)
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
            .tint(theme.accentColor)
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

    @Environment(\.appTheme) private var theme

    let title: String
    var onHelp: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.appBadge)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            if let onHelp {
                Button(action: onHelp) {
                    Image(systemName: "questionmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About \(title)")
            }
        }
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
    var onHelp: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                InfotainmentSectionHeader(title: title)

                if let onHelp {
                    Button(action: onHelp) {
                        Image(systemName: "questionmark.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("About \(title)")
                }
            }

            ChipFlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let selected = selection == option

                    Button {
                        selection = option
                    } label: {
                        Text(itemTitle(option))
                            .font(.caption.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
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
                    .fixedSize(horizontal: true, vertical: true)
                }
            }
        }
    }
}

private struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let result = arrange(in: maxWidth, subviews: subviews)
        return CGSize(width: maxWidth.isFinite ? maxWidth : result.width, height: result.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = arrange(in: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            let size = result.sizes[index]
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: ProposedViewSize(size)
            )
        }
    }

    private func arrange(
        in maxWidth: CGFloat,
        subviews: Subviews
    ) -> (origins: [CGPoint], sizes: [CGSize], width: CGFloat, height: CGFloat) {
        var origins: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let proposedWidth = maxWidth.isFinite ? maxWidth : nil
            var size = subview.sizeThatFits(ProposedViewSize(width: proposedWidth, height: nil))
            if maxWidth.isFinite {
                size.width = min(size.width, maxWidth)
            }

            if maxWidth.isFinite, x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            origins.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
        }

        return (origins, sizes, usedWidth, y + rowHeight)
    }
}
