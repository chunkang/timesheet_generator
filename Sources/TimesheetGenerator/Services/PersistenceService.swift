import Foundation

actor PersistenceService {
    static let shared = PersistenceService()

    private let storageDirectory: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        storageDirectory = appSupport.appendingPathComponent("TimesheetGenerator", isDirectory: true)
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    private func fileURL(for filename: String) -> URL {
        storageDirectory.appendingPathComponent(filename)
    }

    func save<T: Codable & Sendable>(_ value: T, to filename: String) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: fileURL(for: filename))
    }

    func load<T: Codable & Sendable>(from filename: String, as type: T.Type) throws -> T? {
        let url = fileURL(for: filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    func delete(_ filename: String) throws {
        let url = fileURL(for: filename)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
