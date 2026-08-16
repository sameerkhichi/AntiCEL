import SwiftUI

struct VehicleAreaHelpSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Related To")
                    .font(.headline.width(.condensed))
                    .tracking(0.8)

                Spacer()

                DashButton(kind: .compact, action: { dismiss() }) {
                    Text("Done")
                }
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

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(VehicleArea.allCases) { area in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: area.iconName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(theme.accentColor)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(area.displayName)
                                    .font(.subheadline.weight(.semibold))

                                Text(area.helpDescription)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(theme.infotainment.ignoresSafeArea())
        .presentationBackground(theme.infotainment)
        .presentationDetents([.medium, .large])
        .appTheme()
    }
}
