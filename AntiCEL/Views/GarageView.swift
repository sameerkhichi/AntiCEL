import SwiftUI
import SwiftData

struct GarageView: View {
    
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

                        VStack(alignment: .leading) {

                            Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                .font(.headline)

                            Text("\(vehicle.currentMileage) km")
                                .foregroundStyle(.secondary)

                        }

                    }

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
}

#Preview {
    GarageView()
}
