import AppIntents
import WidgetKit

struct LogOccurrenceIntent: AppIntent {
    static let title: LocalizedStringResource = "log occurrence"
    static let description = IntentDescription("record an occurrence now")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        let store = try EventStore()
        try await store.add(type: .occurrence, at: .now)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
