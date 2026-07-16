//Create modal for the main index page view

import SwiftUI
import SwiftData

struct AddVehicleView: View {

    @Environment(\.dismiss) private var dismiss
    //model context acts as a "database session" within the backend.
    @Environment(\.modelContext) private var modelContext

    //these variables will redraw the UI, thats @state.
    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var nickname = ""
    @State private var mileage = ""
    
    //a function that lets us save this view and its info into the model.
    private func saveVehicle() {

        guard let year = Int(year), //guard shows a string rather than the int
              let mileage = Int(mileage)
        else {
            return
        }


        let vehicle = Vehicle(
            make: make,
            model: model,
            year: year,
            nickname: nickname,
            currentMileage: mileage
        )


        modelContext.insert(vehicle)

        dismiss()
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Vehicle Information") {
                    
                    // $is a binding
                    //this basically gives this view permission to change that specific value.
                    TextField("Year", text: $year)

                    TextField("Make", text: $make)

                    TextField("Model", text: $model)

                    TextField("Nickname", text: $nickname)

                    TextField("Mileage", text: $mileage)
                }
            }
            .navigationTitle("Add Vehicle")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Save") {
                        saveVehicle() //call the save funciton 
                    }
                }
            }
        }
    }
}


#Preview {
    AddVehicleView()
}
