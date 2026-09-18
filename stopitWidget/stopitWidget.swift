import SwiftUI
import WidgetKit
import AppIntents

struct StopitWidgetEntry: TimelineEntry {
    let date: Date
    let urgesToday: Int
    let occurrencesToday: Int
    let occurrencesThisWeek: Int
    let weeklyGoal: Int
}

struct StopitWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> StopitWidgetEntry {
        .preview
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (StopitWidgetEntry) -> Void
    ) {
        if context.isPreview {
            completion(.preview)
            return
        }
        loadEntry(completion: completion)
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<StopitWidgetEntry>) -> Void
    ) {
        loadEntry { entry in
            let calendar = Calendar.autoupdatingCurrent
            let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: .now)
            ) ?? .now.addingTimeInterval(3_600)
            completion(Timeline(entries: [entry], policy: .after(nextDay)))
        }
    }

    private func loadEntry(completion: @escaping (StopitWidgetEntry) -> Void) {
        Task {
            do {
                let events = try await EventStore().fetchAll()
                let settingsStore = try SettingsStore()
                let settings = await settingsStore.load()
                let today = InsightCalculator.todayCounts(events: events)
                completion(
                    StopitWidgetEntry(
                        date: .now,
                        urgesToday: today.urges,
                        occurrencesToday: today.occurrences,
                        occurrencesThisWeek: InsightCalculator.currentWeekOccurrences(
                            events: events
                        ),
                        weeklyGoal: settings.weeklyOccurrenceGoal
                    )
                )
            } catch {
                completion(.empty)
            }
        }
    }
}

struct stopitWidget: Widget {
    let kind = "stopitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StopitWidgetProvider()) { entry in
            StopitWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
                .widgetURL(URL(string: "stopit://today"))
        }
        .configurationDisplayName("stopit")
        .description("log an urge or occurrence without opening stopit.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct StopitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StopitWidgetEntry

    var body: some View {
        if family == .systemSmall {
            smallContent
        } else {
            mediumContent
        }
    }

    private var smallContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("stopit")
                .font(.headline)
            HStack {
                CountLabel(value: entry.urgesToday, label: "urges")
                Spacer(minLength: 4)
                CountLabel(value: entry.occurrencesToday, label: "did it")
            }
            Spacer(minLength: 1)
            HStack(spacing: 7) {
                WidgetLogButton(title: "urge", intent: LogUrgeIntent())
                WidgetLogButton(title: "did it", intent: LogOccurrenceIntent())
            }
        }
        .foregroundStyle(.white)
    }

    private var mediumContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("stopit")
                    .font(.headline)
                Spacer()
                Text("\(entry.occurrencesThisWeek) / \(entry.weeklyGoal) this week")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color(white: 0.7))
            }
            HStack {
                CountLabel(value: entry.urgesToday, label: "urges")
                Spacer()
                CountLabel(value: entry.occurrencesToday, label: "occurrences")
            }
            HStack(spacing: 10) {
                WidgetLogButton(title: "urge", intent: LogUrgeIntent())
                WidgetLogButton(title: "did it", intent: LogOccurrenceIntent())
            }
        }
        .foregroundStyle(.white)
    }
}

private struct CountLabel: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(value)")
                .font(.title3.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color(white: 0.68))
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

private struct WidgetLogButton<I: AppIntent>: View {
    let title: String
    let intent: I

    var body: some View {
        Button(intent: intent) {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(Color(white: 0.14))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color(white: 0.3), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title == "urge" ? "log urge" : "log occurrence")
    }
}

extension StopitWidgetEntry {
    static let preview = StopitWidgetEntry(
        date: .now,
        urgesToday: 2,
        occurrencesToday: 1,
        occurrencesThisWeek: 3,
        weeklyGoal: 7
    )

    static let empty = StopitWidgetEntry(
        date: .now,
        urgesToday: 0,
        occurrencesToday: 0,
        occurrencesThisWeek: 0,
        weeklyGoal: 7
    )
}

#Preview(as: .systemSmall) {
    stopitWidget()
} timeline: {
    StopitWidgetEntry.preview
}

#Preview(as: .systemMedium) {
    stopitWidget()
} timeline: {
    StopitWidgetEntry.preview
}
