import SwiftUI

struct EventRow: View {
    let event: HabitEvent
    var showDivider = true

    var body: some View {
        HStack {
            Text(event.type.displayName)
                .font(.body.weight(.medium))
            Spacer()
            Text(contextualTimestamp)
                .font(.subheadline)
                .foregroundStyle(StopitTheme.secondary)
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.type.displayName), \(accessibleTimestamp)")
        .overlay(alignment: .bottom) {
            if showDivider {
                Rectangle()
                    .fill(StopitTheme.border)
                    .frame(height: 0.5)
            }
        }
    }

    private var contextualTimestamp: String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDateInToday(event.timestamp) {
            return event.timestamp.formatted(date: .omitted, time: .shortened)
        }
        if calendar.isDateInYesterday(event.timestamp) {
            return "yesterday, \(event.timestamp.formatted(date: .omitted, time: .shortened))"
        }
        return event.timestamp.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
        ).lowercased()
    }

    private var accessibleTimestamp: String {
        event.timestamp.formatted(date: .complete, time: .shortened).lowercased()
    }
}
