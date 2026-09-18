import XCTest
@testable import stopit

final class EventStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testAddingAnUrge() async throws {
        let store = try EventStore(directoryURL: directory)
        try await store.add(type: .urge, at: Date(timeIntervalSince1970: 100))

        let events = try await store.fetchAll()
        XCTAssertEqual(events.map(\.type), [.urge])
    }

    func testAddingAnOccurrence() async throws {
        let store = try EventStore(directoryURL: directory)
        try await store.add(type: .occurrence, at: Date(timeIntervalSince1970: 100))

        let events = try await store.fetchAll()
        XCTAssertEqual(events.map(\.type), [.occurrence])
    }

    func testEditingAnEvent() async throws {
        let store = try EventStore(directoryURL: directory)
        let event = HabitEvent(type: .urge, timestamp: Date(timeIntervalSince1970: 100))
        try await store.update(event)

        var edited = event
        edited.type = .occurrence
        edited.timestamp = Date(timeIntervalSince1970: 200)
        try await store.update(edited)

        let events = try await store.fetchAll()
        XCTAssertEqual(events, [edited])
    }

    func testDeletingAnEvent() async throws {
        let store = try EventStore(directoryURL: directory)
        let event = HabitEvent(type: .urge, timestamp: .now)
        try await store.update(event)
        try await store.delete(id: event.id)

        let events = try await store.fetchAll()
        XCTAssertTrue(events.isEmpty)
    }

    func testEventsSortNewestFirst() async throws {
        let store = try EventStore(directoryURL: directory)
        let old = HabitEvent(type: .urge, timestamp: Date(timeIntervalSince1970: 100))
        let new = HabitEvent(type: .occurrence, timestamp: Date(timeIntervalSince1970: 200))
        try await store.update(old)
        try await store.update(new)

        let eventIDs = try await store.fetchAll().map(\.id)
        XCTAssertEqual(eventIDs, [new.id, old.id])
    }

    func testEachEventUsesAnIndividualFileAndStoresAreShared() async throws {
        let firstStore = try EventStore(directoryURL: directory)
        let secondStore = try EventStore(directoryURL: directory)
        try await firstStore.add(type: .urge, at: .now)
        try await secondStore.add(type: .occurrence, at: .now)

        let files = try FileManager.default.contentsOfDirectory(
            at: directory.appendingPathComponent("events"),
            includingPropertiesForKeys: nil
        )
        XCTAssertEqual(files.filter { $0.pathExtension == "json" }.count, 2)
        let firstEvents = try await firstStore.fetchAll()
        let secondEvents = try await secondStore.fetchAll()
        XCTAssertEqual(firstEvents.count, 2)
        XCTAssertEqual(secondEvents.count, 2)
    }
}

final class InsightCalculatorTests: XCTestCase {
    private var calendar: Calendar!
    private var now: Date!

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        now = calendar.date(from: DateComponents(
            year: 2026,
            month: 9,
            day: 18,
            hour: 12
        ))!
    }

    func testDailyAggregation() {
        let events = [
            event(.urge, daysAgo: 1),
            event(.urge, daysAgo: 1, hour: 18),
            event(.occurrence, daysAgo: 1)
        ]
        let points = InsightCalculator.dailyPoints(
            events: events,
            days: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(points[5].urges, 2)
        XCTAssertEqual(points[5].occurrences, 1)
    }

    func testZeroCountDaysAreGenerated() {
        let points = InsightCalculator.dailyPoints(
            events: [],
            days: 7,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(points.count, 7)
        XCTAssertTrue(points.allSatisfy { $0.urges == 0 && $0.occurrences == 0 })
    }

    func testSevenDayRangeBoundaries() {
        assertRangeBoundaries(days: 7)
    }

    func testThirtyDayRangeBoundaries() {
        assertRangeBoundaries(days: 30)
    }

    func testNinetyDayRangeBoundaries() {
        assertRangeBoundaries(days: 90)
    }

    func testCurrentWeekOccurrenceCount() {
        let monday = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let events = [
            HabitEvent(type: .occurrence, timestamp: monday),
            HabitEvent(type: .occurrence, timestamp: now),
            HabitEvent(type: .urge, timestamp: now),
            HabitEvent(
                type: .occurrence,
                timestamp: calendar.date(byAdding: .second, value: -1, to: monday)!
            ),
            HabitEvent(
                type: .occurrence,
                timestamp: calendar.date(byAdding: .hour, value: 1, to: now)!
            )
        ]
        XCTAssertEqual(
            InsightCalculator.currentWeekOccurrences(
                events: events,
                now: now,
                calendar: calendar
            ),
            2
        )
    }

    func testGoalRemainingCalculation() {
        let status = InsightCalculator.goalStatus(count: 3, goal: 7)
        XCTAssertEqual(status.remaining, 4)
        XCTAssertEqual(status.over, 0)
    }

    func testOverGoalCalculation() {
        let status = InsightCalculator.goalStatus(count: 9, goal: 7)
        XCTAssertEqual(status.remaining, 0)
        XCTAssertEqual(status.over, 2)
    }

    func testEstimatedResistedPercentage() {
        XCTAssertEqual(
            InsightCalculator.estimatedResisted(urges: 4, occurrences: 1),
            0.75
        )
        XCTAssertNil(InsightCalculator.estimatedResisted(urges: 0, occurrences: 1))
    }

    func testPreviousPeriodTrend() {
        let events = [
            event(.occurrence, daysAgo: 1),
            event(.occurrence, daysAgo: 8),
            event(.occurrence, daysAgo: 9)
        ]
        XCTAssertEqual(
            InsightCalculator.occurrenceTrend(
                events: events,
                days: 7,
                now: now,
                calendar: calendar
            ),
            TrendComparison(direction: .down, percent: 50)
        )
    }

    func testPreviousPeriodZeroHandling() {
        let events = [event(.occurrence, daysAgo: 1)]
        XCTAssertEqual(
            InsightCalculator.occurrenceTrend(
                events: events,
                days: 7,
                now: now,
                calendar: calendar
            ),
            TrendComparison(direction: .noComparableBaseline, percent: nil)
        )
    }

    private func assertRangeBoundaries(days: Int) {
        let insideFirstDay = event(.urge, daysAgo: days - 1, hour: 0)
        let outside = event(.urge, daysAgo: days)
        let today = event(.occurrence, daysAgo: 0)
        let points = InsightCalculator.dailyPoints(
            events: [insideFirstDay, outside, today],
            days: days,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(points.count, days)
        XCTAssertEqual(points.first?.urges, 1)
        XCTAssertEqual(points.last?.occurrences, 1)
        XCTAssertEqual(points.reduce(0) { $0 + $1.urges }, 1)
    }

    private func event(
        _ type: HabitEventType,
        daysAgo: Int,
        hour: Int = 12
    ) -> HabitEvent {
        let today = calendar.startOfDay(for: now)
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
        return HabitEvent(
            type: type,
            timestamp: calendar.date(byAdding: .hour, value: hour, to: day)!
        )
    }
}

final class SettingsStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        suiteName = "stopit-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testSettingsDefaults() async throws {
        let store = try SettingsStore(defaults: defaults)
        let loaded = await store.load()
        XCTAssertEqual(loaded, .defaultValue)
    }

    func testSettingsPersistence() async throws {
        let store = try SettingsStore(defaults: defaults)
        let settings = HabitSettings(
            habitName: "snacking",
            weeklyOccurrenceGoal: 4,
            hasCompletedOnboarding: true
        )
        try await store.save(settings)
        let loaded = await store.load()
        XCTAssertEqual(loaded, settings)
    }
}
