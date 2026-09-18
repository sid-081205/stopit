import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    @State private var habitName = ""
    @State private var goal = 7
    @State private var isSaving = false
    @State private var confirmation: DataConfirmation?

    private var trimmedName: String {
        habitName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section("habit") {
                TextField("habit name", text: $habitName)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("settings habit name")
            }

            Section {
                Stepper(
                    value: $goal,
                    in: 0...99
                ) {
                    HStack {
                        Text("weekly target")
                        Spacer()
                        Text("\(goal)")
                            .foregroundStyle(StopitTheme.secondary)
                            .monospacedDigit()
                    }
                }
                .accessibilityIdentifier("weekly target stepper")

                HStack {
                    Text("enter target")
                    Spacer()
                    TextField(
                        "0",
                        value: $goal,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 60)
                    .accessibilityLabel("weekly target number")
                    .accessibilityIdentifier("weekly target input")
                }

                Text("actual occurrences per week, from 0 to 99. urges do not count toward this target.")
                    .font(.footnote)
                    .foregroundStyle(StopitTheme.secondary)
            } header: {
                Text("weekly target")
            }

            Section("data") {
                Button("delete all data", role: .destructive) {
                    confirmation = .events
                }
                .accessibilityIdentifier("delete all data")

                Button("reset stopit", role: .destructive) {
                    confirmation = .reset
                }
            } footer: {
                Text("your data stays on this device. stopit does not collect or send it anywhere.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(StopitTheme.background)
        .navigationTitle("settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("save") { save() }
                    .disabled(trimmedName.isEmpty || isSaving)
                    .accessibilityIdentifier("save settings")
            }
        }
        .onAppear {
            habitName = model.settings.habitName
            goal = model.settings.weeklyOccurrenceGoal
        }
        .onChange(of: goal) { _, newValue in
            if newValue < 0 || newValue > 99 {
                goal = newValue.clamped(to: 0...99)
            }
        }
        .confirmationDialog(
            confirmation?.title ?? "",
            isPresented: Binding(
                get: { confirmation != nil },
                set: { if !$0 { confirmation = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let confirmation {
                Button(confirmation.buttonTitle, role: .destructive) {
                    perform(confirmation)
                }
            }
            Button("cancel", role: .cancel) {}
        } message: {
            Text(confirmation?.message ?? "")
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        isSaving = true
        Task {
            var settings = model.settings
            settings.habitName = trimmedName
            settings.weeklyOccurrenceGoal = goal.clamped(to: 0...99)
            if await model.saveSettings(settings) { dismiss() }
            isSaving = false
        }
    }

    private func perform(_ action: DataConfirmation) {
        Task {
            switch action {
            case .events:
                _ = await model.deleteAllEvents()
            case .reset:
                if await model.reset() { dismiss() }
            }
        }
    }
}

private enum DataConfirmation {
    case events
    case reset

    var title: String {
        switch self {
        case .events: "delete all entries?"
        case .reset: "reset stopit?"
        }
    }

    var buttonTitle: String {
        switch self {
        case .events: "delete all data"
        case .reset: "delete data and settings"
        }
    }

    var message: String {
        switch self {
        case .events:
            "this deletes every urge and occurrence. your habit and target stay unchanged."
        case .reset:
            "this deletes every entry and setting, then returns to setup."
        }
    }
}
