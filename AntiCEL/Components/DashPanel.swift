import SwiftUI

struct DashPanel<Content: View>: View {

    @Environment(\.appTheme) private var theme

    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16

    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.panel)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [theme.highlight, theme.edge],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: theme.shadow, radius: 10, y: 5)
            }
    }
}
