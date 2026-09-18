import AppIntents
import WidgetKit

struct LogUrgeIntent: AppIntent {
    static let title: LocalizedStringResource = "log urge"
    static let description = IntentDescription("record an urge now")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        let store = try EventStore()
        try await store.add(type: .urge, at: .now)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
