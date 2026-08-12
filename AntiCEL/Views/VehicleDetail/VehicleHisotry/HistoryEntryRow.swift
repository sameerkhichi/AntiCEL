import SwiftUI

struct HistoryEntryRow: View {

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

                Text(entry.vehicleArea.displayName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                if let mileage = entry.mileage {
                    Text("\(mileage.formatted()) km")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)

        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
        .padding(.horizontal)

    }

}
