import Foundation

enum InsightCalculator {
    static func dailyPoints(
        events: [HabitEvent],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [InsightPoint] {
        guard days > 0 else { return [] }
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: today)!

        return (0..<days).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: start)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let dayEvents = events.filter {
                $0.timestamp >= day && $0.timestamp < nextDay
            }
            return InsightPoint(
                date: day,
                urges: dayEvents.filter { $0.type == .urge }.count,
                occurrences: dayEvents.filter { $0.type == .occurrence }.count
            )
        }
    }

    static func eventsInRange(
        _ events: [HabitEvent],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [HabitEvent] {
        guard days > 0 else { return [] }
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: today)!
        let end = calendar.date(byAdding: .day, value: 1, to: today)!
        return events.filter { $0.timestamp >= start && $0.timestamp < end }
    }

    static func todayCounts(
        events: [HabitEvent],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> (urges: Int, occurrences: Int) {
        let dayEvents = events.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
        return (
            dayEvents.filter { $0.type == .urge }.count,
            dayEvents.filter { $0.type == .occurrence }.count
        )
    }

    static func currentWeekOccurrences(
        events: [HabitEvent],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return 0
        }
        return events.filter {
            $0.type == .occurrence &&
                $0.timestamp >= interval.start &&
                $0.timestamp <= now
        }.count
    }

    static func estimatedResisted(urges: Int, occurrences: Int) -> Double? {
        guard urges > 0 else { return nil }
        return Double(max(urges - occurrences, 0)) / Double(urges)
    }

    static func goalStatus(count: Int, goal: Int) -> (remaining: Int, over: Int) {
        (max(goal - count, 0), max(count - goal, 0))
    }

    static func occurrenceTrend(
        events: [HabitEvent],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> TrendComparison? {
        guard days > 0 else { return nil }
        let today = calendar.startOfDay(for: now)
        let currentStart = calendar.date(
            byAdding: .day,
            value: -(days - 1),
            to: today
        )!
        let currentEnd = calendar.date(byAdding: .day, value: 1, to: today)!
        let previousStart = calendar.date(byAdding: .day, value: -days, to: currentStart)!

        let current = events.filter {
            $0.type == .occurrence &&
                $0.timestamp >= currentStart &&
                $0.timestamp < currentEnd
        }.count
        let previous = events.filter {
            $0.type == .occurrence &&
                $0.timestamp >= previousStart &&
                $0.timestamp < currentStart
        }.count

        guard current > 0 || previous > 0 else { return nil }
        guard previous > 0 else {
            return TrendComparison(direction: .noComparableBaseline, percent: nil)
        }

        let change = Double(current - previous) / Double(previous)
        let percent = Int((abs(change) * 100).rounded())
        let direction: TrendComparison.Direction = if current < previous {
            .down
        } else if current > previous {
            .up
        } else {
            .unchanged
        }
        return TrendComparison(direction: direction, percent: percent)
    }

    static func reasonBreakdown(events: [HabitEvent]) -> [ReasonBreakdown] {
        HabitEventReason.allCases.map { reason in
            ReasonBreakdown(
                reason: reason,
                urges: events.filter { $0.type == .urge && $0.reason == reason }.count,
                occurrences: events.filter { $0.type == .occurrence && $0.reason == reason }.count
            )
        }
    }

    static func leadingReason(
        in breakdown: [ReasonBreakdown],
        type: HabitEventType
    ) -> HabitEventReason? {
        let scored = breakdown.map { item in
            (item.reason, type == .urge ? item.urges : item.occurrences)
        }
        let highest = scored.map(\.1).max() ?? 0
        guard highest > 0 else { return nil }
        let leaders = scored.filter { $0.1 == highest }
        return leaders.count == 1 ? leaders[0].0 : nil
    }
}
