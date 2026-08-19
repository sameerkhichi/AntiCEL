import SwiftUI

struct PhotoStorageHelpSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Photos")
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
                VStack(alignment: .leading, spacing: 18) {
                    helpBlock(
                        title: "Low Storage Mode On",
                        body: "AntiCEL will not save photos directly on the app. It uses them from your camera roll instead, so the app stays smaller."
                    )

                    helpBlock(
                        title: "Low Storage Mode Off",
                        body: "AntiCEL saves duplicate photos on the app itself. Those copies stay available even if you later delete the original from your camera roll."
                    )

                    helpBlock(
                        title: "Remove Saved Photos",
                        body: "This deletes all photos stored on AntiCEL. Photos that exist only in this app, and not in your camera roll, will be permanently deleted."
                    )

                    helpBlock(
                        title: "Sharing a Vehicle",
                        body: "When photos are not stored on the app itself, they will be excluded if you share a vehicle. Sharing will send a copy of the vehicle, and photos that aren’t local to AntiCEL can’t be included. Album photos follow this same storage rule."
                    )
                }
                .padding(20)
            }
        }
        .background(theme.infotainment.ignoresSafeArea())
        .presentationBackground(theme.infotainment)
        .presentationDetents([.medium, .large])
        .appTheme()
    }

    private func helpBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(body)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
