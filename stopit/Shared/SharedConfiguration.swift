import Foundation

enum SharedConfiguration {
    static let appGroupIdentifier: String = {
        if let configured = Bundle.main.object(
            forInfoDictionaryKey: "StopitAppGroupIdentifier"
        ) as? String, !configured.isEmpty, !configured.contains("$(") {
            return configured
        }
        return "group.com.example.stopit"
    }()

    static func containerURL(fileManager: FileManager = .default) throws -> URL {
        guard let url = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw StopitStorageError.sharedContainerUnavailable
        }
        return url
    }

    static func defaults() throws -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            throw StopitStorageError.sharedDefaultsUnavailable
        }
        return defaults
    }
}

enum StopitStorageError: LocalizedError {
    case sharedContainerUnavailable
    case sharedDefaultsUnavailable

    var errorDescription: String? {
        switch self {
        case .sharedContainerUnavailable:
            "shared storage is unavailable."
        case .sharedDefaultsUnavailable:
            "shared settings are unavailable."
        }
    }
}
