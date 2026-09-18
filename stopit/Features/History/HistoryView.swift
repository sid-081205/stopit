import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedEvent: HabitEvent?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if model.events.isEmpty {
                    Text("no entries yet")
                        .foregroundStyle(StopitTheme.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 30)
                } else {
                    ForEach(Array(model.events.enumerated()), id: \.element.id) { index, event in
                        Button {
                            selectedEvent = event
                        } label: {
                            EventRow(
                                event: event,
                                showDivider: index < model.events.count - 1
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(StopitTheme.background.ignoresSafeArea())
        .navigationTitle("history")
        .sheet(item: $selectedEvent) { event in
            EditEventView(event: event)
                .environmentObject(model)
        }
    }
}
