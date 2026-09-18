import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var habitName = ""
    @State private var goal = 7
    @State private var isSaving = false
    @FocusState private var nameIsFocused: Bool

    private var trimmedName: String {
        habitName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Spacer(minLength: 36)
                Text("stopit")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 12) {
                    Text("what do you want to do less often?")
                        .font(.title2.weight(.semibold))
                    TextField("the habit", text: $habitName)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.go)
                        .focused($nameIsFocused)
                        .onSubmit(start)
                        .padding(16)
                        .background(StopitTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityIdentifier("habit name")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("weekly target")
                        .font(.headline)
                    HStack(spacing: 22) {
                        Button {
                            goal = max(0, goal - 1)
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("decrease weekly target")

                        Text("\(goal) \(goal == 1 ? "time" : "times")")
                            .font(.title3.monospacedDigit())
                            .frame(minWidth: 100)
                            .accessibilityIdentifier("weekly target value")

                        Button {
                            goal = min(99, goal + 1)
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("increase weekly target")
                    }
                    Text("the target counts actual occurrences. urges do not count.")
                        .font(.footnote)
                        .foregroundStyle(StopitTheme.secondary)
                }

                Button(action: start) {
                    Text("get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 54)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .disabled(trimmedName.isEmpty || isSaving)
                .accessibilityIdentifier("get started")
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(StopitTheme.background.ignoresSafeArea())
        .onAppear { nameIsFocused = true }
    }

    private func start() {
        guard !trimmedName.isEmpty, !isSaving else { return }
        isSaving = true
        Task {
            var settings = HabitSettings.defaultValue
            settings.habitName = trimmedName
            settings.weeklyOccurrenceGoal = goal
            settings.hasCompletedOnboarding = true
            _ = await model.saveSettings(settings)
            isSaving = false
        }
    }
}
