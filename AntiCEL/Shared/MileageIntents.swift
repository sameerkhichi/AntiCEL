import AppIntents

struct AddMileageIntent: AppIntent {

    static var title: LocalizedStringResource = "Add Mileage"
    static var description = IntentDescription("Add kilometers to a vehicle’s odometer.")
    static var openAppWhenRun = false

    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity

    @Parameter(title: "Kilometers")
    var kilometers: Int

    init() {}

    init(vehicle: VehicleEntity, kilometers: Int) {
        self.vehicle = vehicle
        self.kilometers = kilometers
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$kilometers) km to \(\.$vehicle)")
    }

    func perform() async throws -> some IntentResult {
        try MileageWriter.add(vehicleID: vehicle.id, kilometers: kilometers)
        return .result()
    }
}

struct SetVehicleMileageIntent: AppIntent {

    static var title: LocalizedStringResource = "Set Vehicle Mileage"
    static var description = IntentDescription("Set a vehicle’s current odometer reading.")
    static var openAppWhenRun = false

    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity

    @Parameter(title: "Mileage")
    var mileage: Int

    init() {}

    init(vehicle: VehicleEntity, mileage: Int) {
        self.vehicle = vehicle
        self.mileage = mileage
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Set \(\.$vehicle) mileage to \(\.$mileage) km")
    }

    func perform() async throws -> some IntentResult {
        try MileageWriter.set(vehicleID: vehicle.id, mileage: mileage)
        return .result()
    }
}

struct MileageWidgetConfiguration: WidgetConfigurationIntent {

    static var title: LocalizedStringResource = "Vehicle"
    static var description = IntentDescription("Choose which vehicle’s odometer to show.")

    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity?
}
