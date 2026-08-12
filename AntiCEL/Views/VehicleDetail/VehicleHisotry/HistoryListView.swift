import SwiftUI

struct HistoryListView: View {

    @Bindable var vehicle: Vehicle

    private var groupedEntries: [(String, [HistoryEntry])] {

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: vehicle.historyEntries.sorted {
            $0.date > $1.date
        }) { entry in
            formatter.string(from: entry.date)
        }

        return grouped
            .map { ($0.key, $0.value) }
            .sorted {
                guard
                    let d1 = formatter.date(from: $0.0),
                    let d2 = formatter.date(from: $1.0)
                else {
                    return false
                }

                return d1 > d2
            }

    }

    var body: some View {

        LazyVStack(alignment: .leading, spacing: 24) {

            ForEach(groupedEntries, id: \.0) { month, entries in

                VStack(alignment: .leading, spacing: 12) {

                    Text(month.uppercased())
                        .font(.appBadge)
                        .tracking(1.6)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 12) {

                        ForEach(entries) { entry in

                            NavigationLink {

                                HistoryEntryDetailView(
                                    vehicle: vehicle,
                                    historyEntry: entry
                                )

                            } label: {

                                HistoryEntryRow(entry: entry)

                            }
                            .buttonStyle(.plain)

                        }

                    }

                }

            }

        }
        .padding(.vertical)

    }

}
