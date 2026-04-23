import Foundation

struct AtlassianCredentials: Codable, Sendable {
    let baseURL: String
    let email: String
    let apiToken: String
}

actor AtlassianAuthService: AuthServiceProtocol {
    private let sourceType: DataSourceType
    private var keychainKey: String { sourceType.keychainKeyPrefix + ".credentials" }

    var baseURL: String = ""
    var email: String = ""
    var apiToken: String = ""

    init(sourceType: DataSourceType) {
        self.sourceType = sourceType
    }

    func authenticate() async throws -> AuthResult {
        let credentials = AtlassianCredentials(baseURL: baseURL, email: email, apiToken: apiToken)

        guard !credentials.baseURL.isEmpty, !credentials.email.isEmpty, !credentials.apiToken.isEmpty else {
            throw AuthError.invalidCredentials
        }

        let normalizedBaseURL = credentials.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = URL(string: "\(normalizedBaseURL)/rest/api/3/myself")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let authString = "\(credentials.email):\(credentials.apiToken)"
        guard let authData = authString.data(using: .utf8) else {
            throw AuthError.invalidCredentials
        }
        request.setValue("Basic \(authData.base64EncodedString())", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw AuthError.invalidCredentials
            }
            throw AuthError.networkError("Atlassian API returned status \(httpResponse.statusCode)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let displayName = json?["displayName"] as? String ?? credentials.email

        let savedCredentials = AtlassianCredentials(
            baseURL: normalizedBaseURL,
            email: credentials.email,
            apiToken: credentials.apiToken
        )
        try KeychainService.saveCodable(savedCredentials, forKey: keychainKey)

        // Jira and Confluence share credentials
        if sourceType == .jira {
            try KeychainService.saveCodable(savedCredentials, forKey: DataSourceType.confluence.keychainKeyPrefix + ".credentials")
        } else if sourceType == .confluence {
            try KeychainService.saveCodable(savedCredentials, forKey: DataSourceType.jira.keychainKeyPrefix + ".credentials")
        }

        return AuthResult(displayName: displayName, email: credentials.email)
    }

    func validateCredentials() async throws -> Bool {
        guard let credentials: AtlassianCredentials = try KeychainService.loadCodable(forKey: keychainKey, as: AtlassianCredentials.self) else {
            return false
        }

        let url = URL(string: "\(credentials.baseURL)/rest/api/3/myself")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let authString = "\(credentials.email):\(credentials.apiToken)"
        guard let authData = authString.data(using: .utf8) else { return false }
        request.setValue("Basic \(authData.base64EncodedString())", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        return httpResponse.statusCode == 200
    }

    func disconnect() async throws {
        try KeychainService.delete(forKey: keychainKey)
    }

    func setCredentials(baseURL: String, email: String, apiToken: String) {
        self.baseURL = baseURL
        self.email = email
        self.apiToken = apiToken
    }
}
