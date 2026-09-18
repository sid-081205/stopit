import Foundation

struct InsightPoint: Identifiable, Equatable, Sendable {
    let date: Date
    let urges: Int
    let occurrences: Int

    var id: Date { date }
}

enum InsightRange: Int, CaseIterable, Identifiable {
    case seven = 7
    case thirty = 30
    case ninety = 90

    var id: Int { rawValue }
    var title: String { "\(rawValue) days" }
}

struct TrendComparison: Equatable, Sendable {
    enum Direction: Equatable, Sendable {
        case down
        case up
        case unchanged
        case noComparableBaseline
    }

    let direction: Direction
    let percent: Int?
}
