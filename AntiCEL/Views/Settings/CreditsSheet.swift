import SwiftUI

enum ModelCredit {
    static let title = "Generic Sedan Car"
    static let author = "MMC Works"
    static let source = URL(string: "https://skfb.ly/oIOJC")!
    static let licenseName = "Creative Commons Attribution 4.0 International"
    static let license = URL(string: "https://creativecommons.org/licenses/by/4.0/")!
}

struct CreditsSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Credits")
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("3D vehicle model")
                            .font(.subheadline.weight(.semibold))

                        Text("The car in History is “\(ModelCredit.title)” by \(ModelCredit.author).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("License")
                            .font(.subheadline.weight(.semibold))

                        Text("Licensed under \(ModelCredit.licenseName) (CC BY 4.0). You may share and adapt it, including commercially, with credit to the author.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Changes")
                            .font(.subheadline.weight(.semibold))

                        Text("Adapted for AntiCEL: converted to USDZ and used as an interactive history model with tap zones and part animation. \(ModelCredit.author) does not endorse AntiCEL.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Link("View the model on Sketchfab", destination: ModelCredit.source)
                        .font(.footnote.weight(.semibold))

                    Link("Read the CC BY 4.0 license", destination: ModelCredit.license)
                        .font(.footnote.weight(.semibold))

                    Link("View credits on the web", destination: LegalLinks.credits)
                        .font(.footnote.weight(.semibold))
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
