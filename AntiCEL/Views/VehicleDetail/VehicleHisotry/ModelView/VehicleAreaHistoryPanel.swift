import SwiftUI

struct VehicleAreaHistoryPanel: View {

    @Bindable var vehicle: Vehicle
    let area: VehicleArea

    private var entries: [HistoryEntry] {
        vehicle.historyEntries
            .filter { $0.vehicleArea == area }
            .sorted { $0.date > $1.date }
    }

    private var latestEntry: HistoryEntry? {
        entries.first
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack(alignment: .firstTextBaseline) {

                VStack(alignment: .leading, spacing: 4) {

                    Text(area.displayName)
                        .font(.title3.weight(.semibold))

                    Text(area.prompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                }

                Spacer()

                Image(systemName: area.iconName)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)

            }

            if let latestEntry {

                Text(
                    "Last: \(latestEntry.title) · \(latestEntry.date.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            }

            Divider()

            if entries.isEmpty {

                Text("No \(area.displayName.lowercased()) history yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)

            } else {

                ForEach(entries) { entry in

                    NavigationLink {

                        HistoryEntryDetailView(
                            vehicle: vehicle,
                            historyEntry: entry
                        )

                    } label: {

                        HStack(alignment: .top, spacing: 12) {

                            VStack(alignment: .leading, spacing: 4) {

                                Text(entry.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text(
                                    entry.date.formatted(
                                        date: .abbreviated,
                                        time: .omitted
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                if let mileage = entry.mileage {
                                    Text("\(mileage.formatted()) km")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }

                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)

                        }
                        .padding(.vertical, 6)

                    }
                    .buttonStyle(.plain)

                    if entry.id != entries.last?.id {
                        Divider()
                    }

                }

            }

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)

    }

}
