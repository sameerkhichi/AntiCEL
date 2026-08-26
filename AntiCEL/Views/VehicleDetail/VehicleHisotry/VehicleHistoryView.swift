import SwiftUI
import SwiftData

struct VehicleHistoryView: View {

    @Environment(AppSettings.self) private var settings

    @Bindable var vehicle: Vehicle
    var isActive = true

    @State private var displayMode: HistoryDisplayMode = .model
    @State private var showingNewEntry = false
    @State private var showingHint = false

    var body: some View {

        Group {

            switch displayMode {

            case .model:
                HistoryModelView(vehicle: vehicle, isActive: isActive)

            case .list:
                ScrollView {
                    HistoryListView(vehicle: vehicle)
                }

            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar {

            if isActive, settings.showHints {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        AppHaptic.button.play()
                        showingHint = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("About History")
                }
            }

            if isActive {
                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        AppHaptic.button.play()
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
                        AppHaptic.button.play()
                        showingNewEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }

                }
            }

        }
        .sheet(isPresented: $showingNewEntry) {
            HistoryEntryDetailView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingHint) {
            HintSheet(topic: .history)
        }

    }

}
