import AppIntents
import Foundation

struct VehicleEntity: AppEntity, Identifiable, Hashable {

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Vehicle"
    static var defaultQuery = VehicleEntityQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
    }
}

struct VehicleEntityQuery: EntityQuery {

    func entities(for identifiers: [UUID]) async throws -> [VehicleEntity] {
        try MileageWriter.entities(for: identifiers)
    }

    func suggestedEntities() async throws -> [VehicleEntity] {
        try MileageWriter.allEntities()
    }

    func defaultResult() async -> VehicleEntity? {
        try? MileageWriter.allEntities().first
    }
}

extension VehicleEntityQuery: EntityStringQuery {

    func entities(matching string: String) async throws -> [VehicleEntity] {
        try MileageWriter.allEntities().filter {
            $0.name.localizedCaseInsensitiveContains(string)
        }
    }
}
