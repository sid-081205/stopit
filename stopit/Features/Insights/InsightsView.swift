import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedRange = InsightRange.seven

    private var points: [InsightPoint] {
        InsightCalculator.dailyPoints(
            events: model.events,
            days: selectedRange.rawValue
        )
    }

    private var rangeEvents: [HabitEvent] {
        InsightCalculator.eventsInRange(
            model.events,
            days: selectedRange.rawValue
        )
    }

    private var totalUrges: Int {
        rangeEvents.filter { $0.type == .urge }.count
    }

    private var totalOccurrences: Int {
        rangeEvents.filter { $0.type == .occurrence }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("insights")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                Picker("range", selection: $selectedRange) {
                    ForEach(InsightRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("insight range")

                chartCard

                if totalUrges == 0 && totalOccurrences == 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("no data yet")
                            .font(.headline)
                        Text("log an urge or occurrence to start seeing your trend.")
                            .font(.subheadline)
                            .foregroundStyle(StopitTheme.secondary)
                    }
                }

                summaryGrid
                weeklyTargetCard
                trendView
                reasonTrends
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(StopitTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 18) {
                Label("occurrences", systemImage: "square.fill")
                    .foregroundStyle(.white)
                Label("urges", systemImage: "circle.fill")
                    .foregroundStyle(StopitTheme.secondary)
            }
            .font(.caption)

            Chart(points) { point in
                LineMark(
                    x: .value("date", point.date),
                    y: .value("occurrences", point.occurrences),
                    series: .value("series", "occurrences")
                )
                .foregroundStyle(.white)
                .interpolationMethod(.linear)
                PointMark(
                    x: .value("date", point.date),
                    y: .value("occurrences", point.occurrences)
                )
                .foregroundStyle(.white)
                .symbol(.square)

                LineMark(
                    x: .value("date", point.date),
                    y: .value("urges", point.urges),
                    series: .value("series", "urges")
                )
                .foregroundStyle(StopitTheme.secondary)
                .interpolationMethod(.linear)
                PointMark(
                    x: .value("date", point.date),
                    y: .value("urges", point.urges)
                )
                .foregroundStyle(StopitTheme.secondary)
                .symbol(.circle)
            }
            .chartYScale(domain: .automatic(includesZero: true))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: axisStride)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(StopitTheme.border)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(StopitTheme.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(StopitTheme.border)
                    AxisValueLabel()
                        .foregroundStyle(StopitTheme.secondary)
                }
            }
            .chartPlotStyle { plot in
                plot.background(Color.black)
            }
            .frame(height: 250)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("daily urges and occurrences")
            .accessibilityValue(accessibleChartDescription)
        }
        .modifier(InsightsCardModifier())
    }

    private var summaryGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            InsightMetric(title: "total urges", value: "\(totalUrges)")
            InsightMetric(title: "total occurrences", value: "\(totalOccurrences)")
            InsightMetric(
                title: "average per day",
                value: Double(totalOccurrences).formatted(
                    .number.precision(.fractionLength(1))
                )
            )
            if let resisted = InsightCalculator.estimatedResisted(
                urges: totalUrges,
                occurrences: totalOccurrences
            ) {
                InsightMetric(
                    title: "estimated resisted",
                    value: resisted.formatted(
                        .percent.precision(.fractionLength(0))
                    )
                )
            }
        }
    }

    private var weeklyTargetCard: some View {
        let count = InsightCalculator.currentWeekOccurrences(events: model.events)
        let goal = model.settings.weeklyOccurrenceGoal
        let status = InsightCalculator.goalStatus(count: count, goal: goal)

        return VStack(alignment: .leading, spacing: 8) {
            Text("weekly target")
                .font(.headline)
            Text("\(count) of \(goal)")
                .font(.title2.monospacedDigit().weight(.semibold))
            if status.over > 0 {
                Text("\(status.over) over target")
                    .foregroundStyle(StopitTheme.secondary)
            } else if goal == 0 {
                Text("goal is 0")
                    .foregroundStyle(StopitTheme.secondary)
            } else {
                Text("\(status.remaining) remaining")
                    .foregroundStyle(StopitTheme.secondary)
            }
        }
        .modifier(InsightsCardModifier())
    }

    @ViewBuilder
    private var trendView: some View {
        if let trend = InsightCalculator.occurrenceTrend(
            events: model.events,
            days: selectedRange.rawValue
        ) {
            Text(trendText(trend))
                .font(.subheadline)
                .foregroundStyle(StopitTheme.secondary)
                .padding(.horizontal, 2)
        }
    }

    private var reasonTrends: some View {
        let breakdown = InsightCalculator.reasonBreakdown(events: rangeEvents)
        let hasNotes = breakdown.contains { $0.total > 0 }
        let leadingUrge = InsightCalculator.leadingReason(in: breakdown, type: .urge)
        let leadingOccurrence = InsightCalculator.leadingReason(
            in: breakdown,
            type: .occurrence
        )

        return VStack(alignment: .leading, spacing: 16) {
            Text("reasons")
                .font(.headline)

            if hasNotes {
                Chart {
                    ForEach(breakdown) { item in
                        BarMark(
                            x: .value("reason", item.reason.displayName),
                            y: .value("urges", item.urges)
                        )
                        .foregroundStyle(StopitTheme.secondary)
                        .position(by: .value("series", "urges"))

                        BarMark(
                            x: .value("reason", item.reason.displayName),
                            y: .value("occurrences", item.occurrences)
                        )
                        .foregroundStyle(.white)
                        .position(by: .value("series", "occurrences"))
                    }
                }
                .chartLegend(.hidden)
                .chartYScale(domain: .automatic(includesZero: true))
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(StopitTheme.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(StopitTheme.border)
                        AxisValueLabel()
                            .foregroundStyle(StopitTheme.secondary)
                    }
                }
                .chartPlotStyle { plot in
                    plot.background(Color.black)
                }
                .frame(height: 170)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("reason notes for urges and occurrences")
                .accessibilityValue(accessibleReasonDescription(breakdown))

                HStack(spacing: 18) {
                    Label("occurrences", systemImage: "square.fill")
                        .foregroundStyle(.white)
                    Label("urges", systemImage: "circle.fill")
                        .foregroundStyle(StopitTheme.secondary)
                }
                .font(.caption)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(breakdown) { item in
                        HStack {
                            Text(item.reason.displayName)
                            Spacer()
                            Text("\(item.urges) urges · \(item.occurrences) did it")
                                .foregroundStyle(StopitTheme.secondary)
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                }

                if let leadingUrge {
                    Text("most common urge note: \(leadingUrge.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(StopitTheme.secondary)
                }
                if let leadingOccurrence {
                    Text("most common did it note: \(leadingOccurrence.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(StopitTheme.secondary)
                }
            } else {
                Text("add a note after logging to see these trends.")
                    .font(.subheadline)
                    .foregroundStyle(StopitTheme.secondary)
            }
        }
        .modifier(InsightsCardModifier())
    }

    private var axisStride: Int {
        switch selectedRange {
        case .seven: 1
        case .thirty: 5
        case .ninety: 15
        }
    }

    private var accessibleChartDescription: String {
        points.map { point in
            let date = point.date.formatted(date: .abbreviated, time: .omitted)
            return "\(date): \(point.urges) urges, \(point.occurrences) occurrences"
        }.joined(separator: "; ").lowercased()
    }

    private func accessibleReasonDescription(_ breakdown: [ReasonBreakdown]) -> String {
        breakdown.map { item in
            "\(item.reason.displayName): \(item.urges) urges, \(item.occurrences) occurrences"
        }.joined(separator: "; ")
    }

    private func trendText(_ trend: TrendComparison) -> String {
        switch trend.direction {
        case .down:
            "occurrences are down \(trend.percent ?? 0)% from the previous \(selectedRange.rawValue) days"
        case .up:
            "occurrences are up \(trend.percent ?? 0)% from the previous \(selectedRange.rawValue) days"
        case .unchanged:
            "occurrences are unchanged from the previous \(selectedRange.rawValue) days"
        case .noComparableBaseline:
            "the previous \(selectedRange.rawValue) days had no occurrences"
        }
    }
}

private struct InsightMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.title2.monospacedDigit().weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(StopitTheme.secondary)
        }
        .modifier(InsightsCardModifier())
    }
}

private struct InsightsCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StopitTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(StopitTheme.border, lineWidth: 0.5)
            }
    }
}
