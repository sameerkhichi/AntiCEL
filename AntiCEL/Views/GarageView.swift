import SwiftUI
import SwiftData

struct GarageView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]
    //used to detect if we are showing the modal for creating a new vehicle.
    @State private var showingAddVehicle = false
    var body: some View {

        NavigationStack {

            List {

                if vehicles.isEmpty {

                    VStack(spacing: 20) {

                        Image(systemName: "car.2.fill")
                            .font(.system(size: 60))

                        Text("No vehicles yet.")

                    }
                    .frame(maxWidth: .infinity)

                } else {

                    ForEach(vehicles) { vehicle in

                        NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {

                            VStack(alignment: .leading, spacing: 4) {

                                Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                    .font(.headline)

                                if !vehicle.nickname.isEmpty {
                                    Text(vehicle.nickname)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(vehicle.currentMileage.formatted()) km")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                            }
                            .padding(.vertical, 4)

                        }

                    }
                    .onDelete(perform: deleteVehicles)

                }

            }
            .navigationTitle("ANTICEL")
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {

                        showingAddVehicle = true

                    } label: {

                        Image(systemName: "plus")

                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
        }
    }
    
    //function to delete a vehicle on the main page.
    private func deleteVehicles(at offsets: IndexSet) {
        for index in offsets{
            modelContext.delete(vehicles[index])
        }
    }
}

#Preview {
    GarageView()
}
