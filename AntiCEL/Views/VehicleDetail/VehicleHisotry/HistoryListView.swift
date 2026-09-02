import SwiftUI
import SwiftData

struct HistoryListView: View {

    @Environment(\.modelContext) private var modelContext

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
        List {
            ForEach(groupedEntries, id: \.0) { month, entries in
                Section {
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
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(month.uppercased())
                        .font(.appBadge)
                        .tracking(1.6)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listSectionSpacing(18)
    }

    private func delete(_ entry: HistoryEntry) {
        PhotoStore.deleteAppFile(entry.photoFileName)
        modelContext.delete(entry)
        ReminderNotifications.refresh(using: modelContext)
    }

}
