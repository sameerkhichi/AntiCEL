import Foundation
import SwiftData
import WidgetKit

enum WidgetReloader {
    static func reload() {
        WidgetCenter.shared.reloadTimelines(ofKind: AntiCELWidgetKind.mileage)
    }
}

enum MileageWriter {

    static func add(vehicleID: UUID, kilometers: Int) throws {
        try update(vehicleID: vehicleID) { vehicle in
            vehicle.currentMileage = max(vehicle.currentMileage + kilometers, 0)
        }
    }

    static func set(vehicleID: UUID, mileage: Int) throws {
        try update(vehicleID: vehicleID) { vehicle in
            vehicle.currentMileage = max(mileage, 0)
        }
    }

    static func snapshot(for vehicleID: UUID?) throws -> MileageSnapshot? {
        let vehicles = try fetchVehicles()
        let vehicle: Vehicle?
        if let vehicleID {
            vehicle = vehicles.first(where: { $0.id == vehicleID })
        } else {
            vehicle = vehicles.first
        }

        guard let vehicle else {
            return nil
        }

        return MileageSnapshot(
            vehicleID: vehicle.id,
            name: displayName(for: vehicle),
            mileage: vehicle.currentMileage,
            photoRef: vehicle.photoFileName,
            photoFraming: vehicle.photoFraming
        )
    }

    static func entities(for identifiers: [UUID]) throws -> [VehicleEntity] {
        try fetchVehicles()
            .filter { identifiers.contains($0.id) }
            .map(makeEntity(from:))
    }

    static func allEntities() throws -> [VehicleEntity] {
        try fetchVehicles().map(makeEntity(from:))
    }

    static func displayName(for vehicle: Vehicle) -> String {
        if !vehicle.nickname.isEmpty {
            return vehicle.nickname
        }
        return "\(vehicle.year) \(vehicle.make) \(vehicle.model)"
    }

    private static func update(vehicleID: UUID, mutate: (Vehicle) -> Void) throws {
        let container = try SharedModelContainer.make()
        let context = ModelContext(container)
        let target = vehicleID
        var descriptor = FetchDescriptor<Vehicle>(
            predicate: #Predicate { $0.id == target }
        )
        descriptor.fetchLimit = 1

        guard let vehicle = try context.fetch(descriptor).first else {
            return
        }

        mutate(vehicle)
        vehicle.updatedAt = Date()
        try context.save()
        WidgetReloader.reload()
    }

    private static func fetchVehicles() throws -> [Vehicle] {
        let container = try SharedModelContainer.make()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Vehicle>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    private static func makeEntity(from vehicle: Vehicle) -> VehicleEntity {
        VehicleEntity(id: vehicle.id, name: displayName(for: vehicle))
    }
}

struct MileageSnapshot {
    var vehicleID: UUID
    var name: String
    var mileage: Int
    var photoRef: String? = nil
    var photoFraming: PhotoFraming = .identity
}
