import SwiftUI

struct VehicleSectionTabBar: View {

    @Environment(\.appTheme) private var theme
    @Binding var selection: VehicleDetailSection

    var body: some View {
        HStack(spacing: 6) {
            ForEach(VehicleDetailSection.allCases) { section in
                let isSelected = selection == section

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selection = section
                    }
                } label: {
                    VStack(spacing: 5) {
                        DashLED(isOn: isSelected)

                        Image(systemName: section.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .symbolEffect(.bounce, value: isSelected)

                        Text(section.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(DashButtonStyle(isSelected: isSelected, kind: .key))
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.housing)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [theme.highlight.opacity(0.5), theme.edge],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: theme.shadow, radius: 14, y: 6)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }
}
