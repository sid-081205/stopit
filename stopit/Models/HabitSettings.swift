import Foundation

struct HabitSettings: Codable, Equatable, Sendable {
    var habitName: String
    var weeklyOccurrenceGoal: Int
    var hasCompletedOnboarding: Bool

    static let defaultValue = HabitSettings(
        habitName: "the habit",
        weeklyOccurrenceGoal: 7,
        hasCompletedOnboarding: false
    )

    mutating func normalize() {
        habitName = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        weeklyOccurrenceGoal = weeklyOccurrenceGoal.clamped(to: 0...99)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
