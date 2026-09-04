import SwiftUI

struct HistoryEntryRow: View {

    @Environment(AppSettings.self) private var settings

    let entry: HistoryEntry

    private var formattedDate: String {
        entry.date.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        DashPanel(padding: 14, cornerRadius: 14) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: entry.category.systemImage)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.displayTitle)
                        .font(.headline)

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(entry.resolvedVehicleArea.displayName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    if let mileage = entry.mileage {
                        Text(settings.formattedMileage(mileage))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if entry.isAutoScannedFault {
                        ScannedFaultVerificationBadge()
                    }
                }

                Spacer()

                if entry.photoFileName != nil {
                    PhotoThumbnail(ref: entry.photoFileName)
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal)
    }
}
