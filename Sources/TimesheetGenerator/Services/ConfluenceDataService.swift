import Foundation

actor ConfluenceDataService: DataSourceService {
    nonisolated let sourceType: DataSourceType = .confluence

    private let keychainKey = DataSourceType.confluence.keychainKeyPrefix + ".credentials"

    func fetchActivities(from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry] {
        guard let credentials: AtlassianCredentials = try KeychainService.loadCodable(
            forKey: keychainKey, as: AtlassianCredentials.self
        ) else {
            throw DataServiceError.notAuthenticated
        }

        let pages = try await fetchRecentContent(credentials: credentials, from: startDate, to: endDate)
        return pages.sorted { $0.date < $1.date }
    }

    private func fetchRecentContent(credentials: AtlassianCredentials, from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry] {
        let url = URL(string: "\(credentials.baseURL)/wiki/rest/api/content?type=page&orderby=lastmodified&limit=50&expand=version,space,history")!
        let request = makeRequest(url: url, credentials: credentials)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataServiceError.apiError("Invalid response")
        }

        if httpResponse.statusCode == 429 { throw DataServiceError.rateLimited }
        guard httpResponse.statusCode == 200 else {
            throw DataServiceError.apiError("Confluence API returned \(httpResponse.statusCode)")
        }

        return parseConfluenceResponse(data: data, startDate: startDate, endDate: endDate)
    }

    private func parseConfluenceResponse(data: Data, startDate: Date, endDate: Date) -> [TimesheetEntry] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return []
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        return results.compactMap { page -> TimesheetEntry? in
            let title = page["title"] as? String ?? "Untitled"
            let spaceInfo = page["space"] as? [String: Any]
            let spaceName = spaceInfo?["name"] as? String ?? "Unknown Space"

            let version = page["version"] as? [String: Any]
            let whenStr = version?["when"] as? String

            let history = page["history"] as? [String: Any]
            let createdStr = history?["createdDate"] as? String

            let dateStr = whenStr ?? createdStr ?? ""
            let date = isoFormatter.date(from: dateStr) ?? fallbackFormatter.date(from: dateStr)

            guard let activityDate = date, activityDate >= startDate && activityDate <= endDate else {
                return nil
            }

            let versionNumber = version?["number"] as? Int ?? 1
            let category = versionNumber == 1 ? "Documentation (Created)" : "Documentation (Edited)"

            return TimesheetEntry(
                date: activityDate,
                source: .confluence,
                project: spaceName,
                description: title,
                duration: 1800,
                category: category
            )
        }
    }

    private func makeRequest(url: URL, credentials: AtlassianCredentials) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let authString = "\(credentials.email):\(credentials.apiToken)"
        if let authData = authString.data(using: .utf8) {
            request.setValue("Basic \(authData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        return request
    }
}
