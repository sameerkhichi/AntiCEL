import SwiftUI
import SwiftData

struct VehicleHistoryView: View {

    @Bindable var vehicle: Vehicle

    @State private var displayMode: HistoryDisplayMode = .model
    @State private var showingNewEntry = false

    var body: some View {

        Group {

            switch displayMode {

            case .model:
                HistoryModelView(vehicle: vehicle)

            case .list:
                ScrollView {
                    HistoryListView(vehicle: vehicle)
                }

            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        displayMode.toggle()
                    }
                } label: {
                    Image(systemName: displayMode.toggleIconName)
                }
                .accessibilityLabel(displayMode.toggleTitle)

            }

            ToolbarItem(placement: .topBarTrailing) {

                Button {
                    showingNewEntry = true
                } label: {
                    Image(systemName: "plus")
                }

            }

        }
        .sheet(isPresented: $showingNewEntry) {
            HistoryEntryDetailView(vehicle: vehicle)
        }

    }

}
