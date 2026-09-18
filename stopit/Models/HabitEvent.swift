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

struct HabitEvent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var type: HabitEventType
    var timestamp: Date
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: HabitEventType,
        timestamp: Date,
        createdAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.createdAt = createdAt
    }
}
