import SwiftUI

struct VehicleDocumentRow: View {

    let document: VehicleDocument

    private var formattedDate: String {
        document.date.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        DashPanel(padding: 14, cornerRadius: 14) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: document.category.iconName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(document.title)
                        .font(.headline)

                    Text(document.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let expirationDate = document.expirationDate {
                        Text(
                            "Expires \(expirationDate.formatted(date: .abbreviated, time: .omitted))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal)
    }
}
