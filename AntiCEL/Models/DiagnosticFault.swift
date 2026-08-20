import Foundation
import SwiftData

enum DiagnosticFaultStatus: String, Codable, CaseIterable {
    case stored
    case pending
    case permanent

    var displayName: String {
        switch self {
        case .stored: return "Stored"
        case .pending: return "Pending"
        case .permanent: return "Permanent"
        }
    }

    var rank: Int {
        switch self {
        case .pending: return 0
        case .stored: return 1
        case .permanent: return 2
        }
    }
}

@Model
final class DiagnosticFault {

    var id: UUID
    var code: String
    var title: String
    var status: DiagnosticFaultStatus
    var firstSeenAt: Date
    var lastSeenAt: Date
    var mileageAtFirstSeen: Int
    var milOn: Bool
    var isActive: Bool
    var promotedToHistory: Bool
    var historyEntryID: UUID?
    var vehicle: Vehicle?

    init(
        code: String,
        title: String,
        status: DiagnosticFaultStatus,
        mileageAtFirstSeen: Int,
        milOn: Bool = false,
        vehicle: Vehicle? = nil
    ) {
        self.id = UUID()
        self.code = code
        self.title = title
        self.status = status
        self.firstSeenAt = Date()
        self.lastSeenAt = Date()
        self.mileageAtFirstSeen = mileageAtFirstSeen
        self.milOn = milOn
        self.isActive = true
        self.promotedToHistory = false
        self.historyEntryID = nil
        self.vehicle = vehicle
    }
}
