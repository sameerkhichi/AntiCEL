import SwiftUI

struct HistoryEntryRow: View {

    @Environment(AppSettings.self) private var settings

    let entry: HistoryEntry

    private var formattedDate: String {
        entry.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var categoryIcon: String {
        switch entry.category {
        case .maintenance:
            return "wrench.and.screwdriver.fill"
        case .repair:
            return "hammer.fill"
        case .modification:
            return "sparkles"
        case .inspection:
            return "checkmark.shield.fill"
        case .registration:
            return "doc.text.fill"
        case .accident:
            return "exclamationmark.triangle.fill"
        case .purchase:
            return "car.fill"
        case .sale:
            return "dollarsign.circle.fill"
        case .note:
            return "note.text"
        }
    }

    var body: some View {
        DashPanel(padding: 14, cornerRadius: 14) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.title)
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
