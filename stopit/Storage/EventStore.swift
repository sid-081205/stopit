import Foundation

protocol EventStoring: Sendable {
    func add(type: HabitEventType, at date: Date) async throws
    func update(_ event: HabitEvent) async throws
    func delete(id: UUID) async throws
    func fetchAll() async throws -> [HabitEvent]
    func deleteAll() async throws
}

actor EventStore: EventStoring {
    private let directoryURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directoryURL: URL? = nil) throws {
        let baseURL = try directoryURL ?? SharedConfiguration.containerURL()
        self.directoryURL = baseURL.appendingPathComponent(
            "events",
            isDirectory: true
        )
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        try FileManager.default.createDirectory(
            at: self.directoryURL,
            withIntermediateDirectories: true
        )
    }

    func add(type: HabitEventType, at date: Date = .now) async throws {
        try write(HabitEvent(type: type, timestamp: date))
    }

    func update(_ event: HabitEvent) async throws {
        try write(event)
    }

    func delete(id: UUID) async throws {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    func fetchAll() async throws -> [HabitEvent] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return try urls
            .map { try decoder.decode(HabitEvent.self, from: Data(contentsOf: $0)) }
            .sorted {
                if $0.timestamp == $1.timestamp {
                    return $0.createdAt > $1.createdAt
                }
                return $0.timestamp > $1.timestamp
            }
    }

    func deleteAll() async throws {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        )
        for url in urls where url.pathExtension == "json" {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func write(_ event: HabitEvent) throws {
        let data = try encoder.encode(event)
        try data.write(to: fileURL(for: event.id), options: .atomic)
    }

    private func fileURL(for id: UUID) -> URL {
        directoryURL.appendingPathComponent(id.uuidString).appendingPathExtension("json")
    }
}
