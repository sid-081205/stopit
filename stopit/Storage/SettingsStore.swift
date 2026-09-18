import Foundation

protocol SettingsStoring: Sendable {
    func load() async -> HabitSettings
    func save(_ settings: HabitSettings) async throws
    func reset() async
}

actor SettingsStore: SettingsStoring {
    private let defaults: UserDefaults
    private let key = "habit-settings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults? = nil) throws {
        self.defaults = try defaults ?? SharedConfiguration.defaults()
    }

    func load() async -> HabitSettings {
        guard
            let data = defaults.data(forKey: key),
            var settings = try? decoder.decode(HabitSettings.self, from: data)
        else {
            return .defaultValue
        }
        settings.normalize()
        return settings
    }

    func save(_ settings: HabitSettings) async throws {
        var normalized = settings
        normalized.normalize()
        defaults.set(try encoder.encode(normalized), forKey: key)
    }

    func reset() async {
        defaults.removeObject(forKey: key)
    }
}
