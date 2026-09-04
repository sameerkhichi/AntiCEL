import SwiftUI

struct VehicleAreaHistoryPanel: View {

    @Environment(AppSettings.self) private var settings

    @Bindable var vehicle: Vehicle
    let area: VehicleArea

    private var entries: [HistoryEntry] {
        vehicle.historyEntries
            .filter { $0.resolvedVehicleArea == area }
            .sorted { $0.date > $1.date }
    }

    private var latestEntry: HistoryEntry? {
        entries.first
    }

    var body: some View {
        DashPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(area.displayName)
                            .font(.title3.weight(.semibold).width(.condensed))

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
                        "Last: \(latestEntry.displayTitle) · \(latestEntry.date.formatted(date: .abbreviated, time: .omitted))"
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }

                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)

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
                                    Text(entry.displayTitle)
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
                                        Text(settings.formattedMileage(mileage))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }

                                    if entry.isAutoScannedFault {
                                        ScannedFaultVerificationBadge()
                                    }
                                }

                                Spacer()

                                if entry.photoFileName != nil {
                                    PhotoThumbnail(ref: entry.photoFileName, size: 32)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)

                        if entry.id != entries.last?.id {
                            Rectangle()
                                .fill(.quaternary)
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
