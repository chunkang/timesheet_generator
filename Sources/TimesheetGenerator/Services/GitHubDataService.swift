import Foundation

actor GitHubDataService: DataSourceService {
    nonisolated let sourceType: DataSourceType = .github

    private let keychainKey = DataSourceType.github.keychainKeyPrefix + ".token"
    private let apiBaseURL = "https://api.github.com"

    func fetchActivities(from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry] {
        guard let token = try KeychainService.loadString(forKey: keychainKey) else {
            throw DataServiceError.notAuthenticated
        }

        async let commits = fetchCommitEvents(token: token, from: startDate, to: endDate)
        async let pullRequests = fetchPRActivity(token: token, from: startDate, to: endDate)

        let allEntries = try await commits + pullRequests
        return allEntries.sorted { $0.date < $1.date }
    }

    private func fetchCommitEvents(token: String, from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry] {
        let url = URL(string: "\(apiBaseURL)/user/repos?per_page=100&sort=pushed&direction=desc")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataServiceError.apiError("Invalid response")
        }

        if httpResponse.statusCode == 429 { throw DataServiceError.rateLimited }
        guard httpResponse.statusCode == 200 else {
            throw DataServiceError.apiError("GitHub API returned \(httpResponse.statusCode)")
        }

        guard let repos = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        let formatter = ISO8601DateFormatter()

        var entries: [TimesheetEntry] = []

        for repo in repos.prefix(10) {
            guard let fullName = repo["full_name"] as? String,
                  let repoName = repo["name"] as? String else { continue }

            let since = formatter.string(from: startDate)
            let until = formatter.string(from: endDate)

            let commitsURL = URL(string: "\(apiBaseURL)/repos/\(fullName)/commits?since=\(since)&until=\(until)&per_page=100")!
            var commitsRequest = URLRequest(url: commitsURL)
            commitsRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            commitsRequest.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

            guard let (commitsData, commitsResponse) = try? await URLSession.shared.data(for: commitsRequest),
                  let commitsHTTP = commitsResponse as? HTTPURLResponse,
                  commitsHTTP.statusCode == 200,
                  let commits = try? JSONSerialization.jsonObject(with: commitsData) as? [[String: Any]] else {
                continue
            }

            let commitsByDate = Dictionary(grouping: commits) { commit -> String in
                let dateStr = (commit["commit"] as? [String: Any])?["author"] as? [String: Any]
                let dateValue = dateStr?["date"] as? String ?? ""
                return String(dateValue.prefix(10))
            }

            for (dateKey, dayCommits) in commitsByDate {
                guard !dayCommits.isEmpty else { continue }

                let messages = dayCommits.compactMap { commit -> String? in
                    let commitInfo = commit["commit"] as? [String: Any]
                    return commitInfo?["message"] as? String
                }

                let firstMessage = messages.first?.components(separatedBy: "\n").first ?? "Commits"
                let description = dayCommits.count == 1
                    ? firstMessage
                    : "\(dayCommits.count) commits: \(firstMessage)"

                let dateComponents = dateKey.split(separator: "-")
                var dc = DateComponents()
                dc.year = Int(dateComponents[safe: 0] ?? "")
                dc.month = Int(dateComponents[safe: 1] ?? "")
                dc.day = Int(dateComponents[safe: 2] ?? "")
                dc.hour = 12

                guard let date = Calendar.current.date(from: dc) else { continue }

                entries.append(TimesheetEntry(
                    date: date,
                    source: .github,
                    project: repoName,
                    description: description,
                    duration: TimeInterval(dayCommits.count) * 1800,
                    category: "Development"
                ))
            }
        }

        return entries
    }

    private func fetchPRActivity(token: String, from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry] {
        let formatter = ISO8601DateFormatter()
        let since = formatter.string(from: startDate)

        let searchQuery = "is:pr+author:@me+updated:>=\(String(since.prefix(10)))"
        let url = URL(string: "\(apiBaseURL)/search/issues?q=\(searchQuery)&per_page=50&sort=updated")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            return []
        }

        return items.compactMap { pr -> TimesheetEntry? in
            guard let title = pr["title"] as? String,
                  let updatedStr = pr["updated_at"] as? String,
                  let date = formatter.date(from: updatedStr),
                  date >= startDate && date <= endDate else { return nil }

            let repoURL = pr["repository_url"] as? String ?? ""
            let repoName = repoURL.components(separatedBy: "/").last ?? "Unknown"
            let prNumber = pr["number"] as? Int ?? 0

            return TimesheetEntry(
                date: date,
                source: .github,
                project: repoName,
                description: "PR #\(prNumber): \(title)",
                duration: 1800,
                category: "Code Review"
            )
        }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
