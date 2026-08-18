//This is a AI generated template for now while I build out the rest of the app.

import SwiftUI

struct HistoryTimelineNode: View {

    @Environment(AppSettings.self) private var settings

    let entry: HistoryEntry
    let isLast: Bool

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

        HStack(alignment: .top, spacing: 16) {

            VStack(spacing: 0) {

                Image(systemName: categoryIcon)
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())

                if !isLast {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }

            }

            VStack(alignment: .leading, spacing: 8) {

                Text(entry.title)
                    .font(.headline)

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let mileage = entry.mileage {
                    Text(settings.formattedMileage(mileage))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if entry.photoFileName != nil {
                    PhotoThumbnail(ref: entry.photoFileName, size: 56)
                }

            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.quaternary)
            }

        }
    }

}
