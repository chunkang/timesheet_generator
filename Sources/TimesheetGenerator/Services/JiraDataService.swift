import Foundation

actor JiraDataService: DataSourceService {
    nonisolated let sourceType: DataSourceType = .jira

    private let keychainKey = DataSourceType.jira.keychainKeyPrefix + ".credentials"

    func fetchActivities(from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry] {
        guard let credentials: AtlassianCredentials = try KeychainService.loadCodable(
            forKey: keychainKey, as: AtlassianCredentials.self
        ) else {
            throw DataServiceError.notAuthenticated
        }

        let worklogs = try await fetchWorklogs(credentials: credentials, from: startDate, to: endDate)
        return worklogs.sorted { $0.date < $1.date }
    }

    private func fetchWorklogs(credentials: AtlassianCredentials, from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startStr = dateFormatter.string(from: startDate)
        let endStr = dateFormatter.string(from: endDate)

        let jql = "worklogDate >= \"\(startStr)\" AND worklogDate <= \"\(endStr)\" AND worklogAuthor = currentUser()"
        let encodedJQL = jql.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? jql

        let url = URL(string: "\(credentials.baseURL)/rest/api/3/search?jql=\(encodedJQL)&fields=summary,worklog,project&maxResults=50")!
        let request = makeRequest(url: url, credentials: credentials)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataServiceError.apiError("Invalid response")
        }

        if httpResponse.statusCode == 429 { throw DataServiceError.rateLimited }
        guard httpResponse.statusCode == 200 else {
            throw DataServiceError.apiError("Jira API returned \(httpResponse.statusCode)")
        }

        return try parseJiraResponse(data: data, startDate: startDate, endDate: endDate)
    }

    private func parseJiraResponse(data: Data, startDate: Date, endDate: Date) throws -> [TimesheetEntry] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let issues = json["issues"] as? [[String: Any]] else {
            return []
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        var entries: [TimesheetEntry] = []

        for issue in issues {
            let issueKey = issue["key"] as? String ?? "Unknown"
            let fields = issue["fields"] as? [String: Any]
            let summary = fields?["summary"] as? String ?? ""
            let projectInfo = fields?["project"] as? [String: Any]
            let projectKey = projectInfo?["key"] as? String ?? "Unknown"

            let worklog = fields?["worklog"] as? [String: Any]
            let worklogs = worklog?["worklogs"] as? [[String: Any]] ?? []

            for log in worklogs {
                guard let startedStr = log["started"] as? String,
                      let timeSpentSeconds = log["timeSpentSeconds"] as? Int else { continue }

                let logDate = isoFormatter.date(from: startedStr) ?? fallbackFormatter.date(from: startedStr)
                guard let date = logDate, date >= startDate && date <= endDate else { continue }

                entries.append(TimesheetEntry(
                    date: date,
                    source: .jira,
                    project: projectKey,
                    description: "\(issueKey): \(summary)",
                    duration: TimeInterval(timeSpentSeconds),
                    category: "Development"
                ))
            }
        }

        return entries
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
