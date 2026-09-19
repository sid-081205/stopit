import SwiftUI
import WidgetKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var settings: HabitSettings = .defaultValue
    @Published private(set) var events: [HabitEvent] = []
    @Published var presentedError: String?
    @Published private(set) var hasLoaded = false

    let eventStore: EventStore?
    let settingsStore: SettingsStore?

    init() {
        do {
            eventStore = try EventStore()
            settingsStore = try SettingsStore()
        } catch {
            eventStore = nil
            settingsStore = nil
            presentedError = error.localizedDescription
        }
    }

    func load() async {
        if
            ProcessInfo.processInfo.arguments.contains("--ui-testing-reset"),
            let eventStore,
            let settingsStore
        {
            try? await eventStore.deleteAll()
            await settingsStore.reset()
        }
        if let settingsStore {
            settings = await settingsStore.load()
        }
        await refreshEvents()
        hasLoaded = true
    }

    func refreshEvents() async {
        guard let eventStore else {
            presentedError = "shared storage is unavailable."
            return
        }
        do {
            events = try await eventStore.fetchAll()
        } catch {
            presentedError = error.localizedDescription
        }
    }

    func log(
        _ type: HabitEventType,
        reason: HabitEventReason? = nil
    ) async -> HabitEvent? {
        guard let eventStore else {
            presentedError = "shared storage is unavailable."
            return nil
        }
        do {
            let event = try await eventStore.add(
                type: type,
                at: .now,
                reason: reason
            )
            events = try await eventStore.fetchAll()
            WidgetCenter.shared.reloadAllTimelines()
            return event
        } catch {
            presentedError = error.localizedDescription
            return nil
        }
    }

    func update(_ event: HabitEvent) async -> Bool {
        guard let eventStore else {
            presentedError = "shared storage is unavailable."
            return false
        }
        do {
            try await eventStore.update(event)
            events = try await eventStore.fetchAll()
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch {
            presentedError = error.localizedDescription
            return false
        }
    }

    func delete(id: UUID) async -> Bool {
        guard let eventStore else {
            presentedError = "shared storage is unavailable."
            return false
        }
        do {
            try await eventStore.delete(id: id)
            events = try await eventStore.fetchAll()
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch {
            presentedError = error.localizedDescription
            return false
        }
    }

    func saveSettings(_ value: HabitSettings) async -> Bool {
        guard let settingsStore else {
            presentedError = "shared settings are unavailable."
            return false
        }
        do {
            try await settingsStore.save(value)
            settings = await settingsStore.load()
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch {
            presentedError = error.localizedDescription
            return false
        }
    }

    func deleteAllEvents() async -> Bool {
        guard let eventStore else {
            presentedError = "shared storage is unavailable."
            return false
        }
        do {
            try await eventStore.deleteAll()
            events = []
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch {
            presentedError = error.localizedDescription
            return false
        }
    }

    func reset() async -> Bool {
        guard let settingsStore else {
            presentedError = "shared settings are unavailable."
            return false
        }
        guard await deleteAllEvents() else { return false }
        await settingsStore.reset()
        settings = .defaultValue
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }
}
