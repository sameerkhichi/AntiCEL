import SwiftUI
import SwiftData

struct VehicleHistoryView: View {

    @Bindable var vehicle: Vehicle

    @State private var displayMode: HistoryDisplayMode = .list
    @State private var showingNewEntry = false

    var body: some View {

        VStack(spacing: 0) {

            Picker("View", selection: $displayMode) {
                ForEach(HistoryDisplayMode.allCases) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Group {

                switch displayMode {

                case .list:
                    HistoryListView(vehicle: vehicle)

                case .timeline:
                    HistoryTimelineView(vehicle: vehicle)

                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
        .navigationTitle("History")
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {

                    showingNewEntry = true

                } label: {

                    Image(systemName: "plus")

                }

            }

        }
        .sheet(isPresented: $showingNewEntry) {

            NavigationStack {
                HistoryEntryDetailView(vehicle: vehicle)
            }

        }

    }

}
