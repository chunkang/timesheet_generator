import Foundation

protocol DataSourceService: Sendable {
    var sourceType: DataSourceType { get }
    func fetchActivities(from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry]
}

enum DataServiceError: LocalizedError, Sendable {
    case notAuthenticated
    case apiError(String)
    case rateLimited
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "Not authenticated. Please reconnect in Settings."
        case .apiError(let message): "API error: \(message)"
        case .rateLimited: "Rate limit exceeded. Please try again later."
        case .decodingError: "Failed to parse response data."
        }
    }
}

struct SourceFetchResult: Sendable {
    let source: DataSourceType
    let entries: [TimesheetEntry]
    let error: Error?

    init(source: DataSourceType, entries: [TimesheetEntry] = [], error: Error? = nil) {
        self.source = source
        self.entries = entries
        self.error = error
    }
}
