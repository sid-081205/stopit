import Foundation

enum HabitEventType: String, Codable, CaseIterable, Sendable {
    case urge
    case occurrence

    var displayName: String {
        switch self {
        case .urge: "urge"
        case .occurrence: "did it"
        }
    }
}

enum HabitEventReason: String, Codable, CaseIterable, Identifiable, Sendable {
    case morning
    case bored
    case trigger
    case night

    var id: String { rawValue }
    var displayName: String { rawValue }
}

struct HabitEvent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var type: HabitEventType
    var timestamp: Date
    var reason: HabitEventReason?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: HabitEventType,
        timestamp: Date,
        reason: HabitEventReason? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.reason = reason
        self.createdAt = createdAt
    }
}
