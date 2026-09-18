import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    @State private var draft: HabitEvent
    @State private var isSaving = false
    @State private var showingDeleteConfirmation = false

    init(event: HabitEvent) {
        _draft = State(initialValue: event)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("type") {
                    Picker("event type", selection: $draft.type) {
                        Text("urge").tag(HabitEventType.urge)
                        Text("did it").tag(HabitEventType.occurrence)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("event type")
                }

                Section("when") {
                    DatePicker(
                        "date",
                        selection: $draft.timestamp,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "time",
                        selection: $draft.timestamp,
                        displayedComponents: .hourAndMinute
                    )
                }

                Section {
                    Button("delete event", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .accessibilityIdentifier("delete event")
                }
            }
            .scrollContentBackground(.hidden)
            .background(StopitTheme.background)
            .navigationTitle("edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        isSaving = true
                        Task {
                            if await model.update(draft) { dismiss() }
                            isSaving = false
                        }
                    }
                    .disabled(isSaving)
                    .accessibilityIdentifier("save event")
                }
            }
            .confirmationDialog(
                "delete this entry?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("delete event", role: .destructive) {
                    isSaving = true
                    Task {
                        if await model.delete(id: draft.id) { dismiss() }
                        isSaving = false
                    }
                }
                Button("cancel", role: .cancel) {}
            } message: {
                Text("this cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }
}
