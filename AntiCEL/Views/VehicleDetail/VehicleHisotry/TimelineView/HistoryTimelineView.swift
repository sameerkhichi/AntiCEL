import SwiftUI

struct HistoryTimelineView: View {

    @Bindable var vehicle: Vehicle

    private var sortedEntries: [HistoryEntry] {
        vehicle.historyEntries.sorted {
            $0.date > $1.date
        }
    }

    var body: some View {

        ScrollView {

            LazyVStack(alignment: .leading, spacing: 24) {

                ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in

                    NavigationLink {

                        HistoryEntryDetailView(
                            vehicle: vehicle,
                            historyEntry: entry
                        )

                    } label: {

                        HistoryTimelineNode(
                            entry: entry,
                            isLast: index == sortedEntries.count - 1
                        )

                    }
                    .buttonStyle(.plain)

                }

            }
            .padding()

        }

    }

}
