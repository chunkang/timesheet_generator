import Foundation

actor GitHubAuthService: AuthServiceProtocol {
    private let keychainKey = DataSourceType.github.keychainKeyPrefix + ".token"
    private let apiBaseURL = "https://api.github.com"

    var personalAccessToken: String = ""

    func authenticate() async throws -> AuthResult {
        let token = personalAccessToken
        guard !token.isEmpty else {
            throw AuthError.invalidCredentials
        }

        let url = URL(string: "\(apiBaseURL)/user")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw AuthError.invalidCredentials
            }
            throw AuthError.networkError("GitHub API returned status \(httpResponse.statusCode)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let login = json?["login"] as? String else {
            throw AuthError.invalidResponse
        }

        try KeychainService.saveString(token, forKey: keychainKey)

        let email = json?["email"] as? String
        return AuthResult(displayName: login, email: email)
    }

    func validateCredentials() async throws -> Bool {
        guard let token = try KeychainService.loadString(forKey: keychainKey) else {
            return false
        }

        let url = URL(string: "\(apiBaseURL)/user")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        return httpResponse.statusCode == 200
    }

    func disconnect() async throws {
        try KeychainService.delete(forKey: keychainKey)
    }

    func setToken(_ token: String) {
        personalAccessToken = token
    }
}
