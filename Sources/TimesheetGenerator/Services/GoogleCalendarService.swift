import Foundation

actor GoogleCalendarService: DataSourceService {
    nonisolated let sourceType: DataSourceType = .google

    private let keychainKey = DataSourceType.google.keychainKeyPrefix + ".tokens"

    func fetchActivities(from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry] {
        guard let tokens: GoogleTokens = try KeychainService.loadCodable(forKey: keychainKey, as: GoogleTokens.self) else {
            throw DataServiceError.notAuthenticated
        }

        let accessToken: String
        if tokens.isExpired {
            let authService = GoogleAuthService()
            let refreshed = try await authService.refreshAccessToken()
            accessToken = refreshed.accessToken
        } else {
            accessToken = tokens.accessToken
        }

        return try await fetchCalendarEvents(accessToken: accessToken, from: startDate, to: endDate)
    }

    private func fetchCalendarEvents(accessToken: String, from startDate: Date, to endDate: Date) async throws -> [TimesheetEntry] {
        let formatter = ISO8601DateFormatter()
        let timeMin = formatter.string(from: startDate)
        let timeMax = formatter.string(from: endDate)

        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeMax", value: timeMax),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "250")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataServiceError.apiError("Invalid response")
        }

        if httpResponse.statusCode == 429 {
            throw DataServiceError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            throw DataServiceError.apiError("Google Calendar API returned \(httpResponse.statusCode)")
        }

        return try parseCalendarEvents(data: data)
    }

    private func parseCalendarEvents(data: Data) throws -> [TimesheetEntry] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            return []
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        return items.compactMap { event -> TimesheetEntry? in
            guard let summary = event["summary"] as? String else { return nil }

            let startDict = event["start"] as? [String: Any]
            let endDict = event["end"] as? [String: Any]

            guard let startStr = startDict?["dateTime"] as? String,
                  let endStr = endDict?["dateTime"] as? String else {
                return nil
            }

            let startDate = dateFormatter.date(from: startStr) ?? fallbackFormatter.date(from: startStr)
            let endDate = dateFormatter.date(from: endStr) ?? fallbackFormatter.date(from: endStr)

            guard let start = startDate, let end = endDate else { return nil }

            let duration = end.timeIntervalSince(start)
            guard duration > 0 else { return nil }

            let calendarName = (event["organizer"] as? [String: Any])?["displayName"] as? String ?? "Calendar"

            return TimesheetEntry(
                date: start,
                source: .google,
                project: calendarName,
                description: summary,
                duration: duration,
                category: "Meeting"
            )
        }
    }
}
