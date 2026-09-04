import SwiftUI

struct FaultCodeRow: View {

    let fault: DiagnosticFault

    var body: some View {
        DashPanel(padding: 14, cornerRadius: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(DTCDictionary.normalizedCode(fault.code))
                        .font(.headline.monospaced().width(.condensed))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(DTCDictionary.description(for: fault.code))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(fault.status.displayName + (fault.isActive ? "" : " · Cleared"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal)
        .opacity(fault.isActive ? 1 : 0.55)
    }

    private var iconName: String {
        DTCHistoryMapper.vehicleArea(for: fault.code).iconName
    }
}
