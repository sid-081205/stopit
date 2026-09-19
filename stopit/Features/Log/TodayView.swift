import SwiftUI
import UIKit

struct TodayView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedEvent: HabitEvent?
    @State private var writingUrge = false
    @State private var writingOccurrence = false
    @State private var confirmation: String?
    @State private var lastLoggedEvent: HabitEvent?
    @State private var confirmationTask: Task<Void, Never>?

    private var counts: (urges: Int, occurrences: Int) {
        InsightCalculator.todayCounts(events: model.events)
    }

    private var weekCount: Int {
        InsightCalculator.currentWeekOccurrences(events: model.events)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, confirmation == nil ? 36 : 12)

                if let confirmation {
                    reasonCard(confirmation)
                        .padding(.bottom, 36)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .opacity.combined(with: .move(edge: .top))
                        )
                }

                actions
                    .padding(.bottom, 36)

                todaySummary
                    .padding(.bottom, 36)

                recentHistory
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: confirmation)
        }
        .background(StopitTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            EditEventView(event: event)
                .environmentObject(model)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("stopit")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text(model.settings.habitName)
                .font(.title3)
                .foregroundStyle(StopitTheme.secondary)
            Text(weeklyProgressText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(StopitTheme.secondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reasonCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(message)
                .font(.body.weight(.medium))
            VStack(alignment: .leading, spacing: 12) {
                Text("why?")
                    .font(.subheadline)
                    .foregroundStyle(StopitTheme.secondary)
                ReasonChipRow(selected: lastLoggedEvent?.reason) { reason in
                    attach(reason)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StopitTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(StopitTheme.border, lineWidth: 0.5)
        }
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var actions: some View {
        VStack(spacing: 16) {
            LogButton(
                title: "urge",
                subtitle: "i felt like doing it",
                isLoading: writingUrge,
                reduceMotion: reduceMotion
            ) {
                log(.urge)
            }
            .accessibilityIdentifier("log urge")

            LogButton(
                title: "did it",
                subtitle: "log an occurrence",
                isLoading: writingOccurrence,
                reduceMotion: reduceMotion
            ) {
                log(.occurrence)
            }
            .accessibilityIdentifier("log occurrence")
        }
    }

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("today")
                .font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 28) {
                SummaryValue(value: counts.urges, label: counts.urges == 1 ? "urge" : "urges")
                SummaryValue(
                    value: counts.occurrences,
                    label: counts.occurrences == 1 ? "occurrence" : "occurrences"
                )
                Spacer(minLength: 0)
            }
            if let resisted = InsightCalculator.estimatedResisted(
                urges: counts.urges,
                occurrences: counts.occurrences
            ) {
                Text("\(resisted, format: .percent.precision(.fractionLength(0))) estimated resisted")
                    .font(.subheadline)
                    .foregroundStyle(StopitTheme.secondary)
            }
        }
        .modifier(CardModifier())
    }

    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("recent")
                    .font(.headline)
                Spacer()
                if model.events.count > 5 {
                    NavigationLink("see all") { HistoryView() }
                        .font(.subheadline)
                }
            }
            .padding(.bottom, 4)

            if model.events.isEmpty {
                Text("your entries will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(StopitTheme.secondary)
                    .padding(.vertical, 18)
            } else {
                ForEach(Array(model.events.prefix(5).enumerated()), id: \.element.id) { index, event in
                    Button {
                        selectedEvent = event
                    } label: {
                        EventRow(
                            event: event,
                            showDivider: index < min(model.events.count, 5) - 1
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var weeklyProgressText: String {
        let goal = model.settings.weeklyOccurrenceGoal
        return goal == 0
            ? "\(weekCount) this week · goal 0"
            : "\(weekCount) of \(goal) this week"
    }

    private func log(_ type: HabitEventType) {
        guard type == .urge ? !writingUrge : !writingOccurrence else { return }
        if type == .urge { writingUrge = true } else { writingOccurrence = true }
        Task {
            if let event = await model.log(type) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                lastLoggedEvent = event
                showConfirmation(type == .urge ? "urge logged" : "logged")
            }
            if type == .urge { writingUrge = false } else { writingOccurrence = false }
        }
    }

    private func attach(_ reason: HabitEventReason?) {
        guard var event = lastLoggedEvent else { return }
        event.reason = reason
        Task {
            if await model.update(event) {
                lastLoggedEvent = event
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showConfirmation(
                    reason == nil
                        ? (event.type == .urge ? "urge logged" : "logged")
                        : "\(event.type.displayName) · \(reason.displayName)"
                )
            }
        }
    }

    private func showConfirmation(_ message: String) {
        confirmationTask?.cancel()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) {
            confirmation = message
        }
        confirmationTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) {
                confirmation = nil
                lastLoggedEvent = nil
            }
        }
    }
}

private struct LogButton: View {
    let title: String
    let subtitle: String
    let isLoading: Bool
    var reduceMotion = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.medium))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(StopitTheme.secondary)
                }
                Spacer(minLength: 8)
                if isLoading {
                    ProgressView()
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(StopitTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(StopitTheme.border, lineWidth: 0.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(SoftPressButtonStyle(reduceMotion: reduceMotion))
        .disabled(isLoading)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

private struct SummaryValue: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title2.monospacedDigit().weight(.semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(StopitTheme.secondary)
        }
    }
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StopitTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(StopitTheme.border, lineWidth: 0.5)
            }
    }
}
