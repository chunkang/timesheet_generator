import Foundation
import CryptoKit
import AuthenticationServices

struct GoogleTokens: Codable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
    let email: String

    var isExpired: Bool {
        Date() >= expiresAt
    }
}

actor GoogleAuthService: AuthServiceProtocol {
    private let clientID: String
    private let redirectURI = "com.kurapa.timesheetgenerator:/oauth/callback"
    private let scopes = "https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/gmail.readonly"
    private let keychainKey = DataSourceType.google.keychainKeyPrefix + ".tokens"

    init(clientID: String = "") {
        self.clientID = clientID
    }

    func authenticate() async throws -> AuthResult {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        let authURL = buildAuthorizationURL(codeChallenge: codeChallenge)

        let callbackURL = try await performWebAuthentication(url: authURL)

        guard let code = extractAuthorizationCode(from: callbackURL) else {
            throw AuthError.invalidResponse
        }

        let tokens = try await exchangeCodeForTokens(code: code, codeVerifier: codeVerifier)
        try KeychainService.saveCodable(tokens, forKey: keychainKey)

        return AuthResult(displayName: tokens.email, email: tokens.email)
    }

    func validateCredentials() async throws -> Bool {
        guard let tokens: GoogleTokens = try KeychainService.loadCodable(forKey: keychainKey, as: GoogleTokens.self) else {
            return false
        }

        if tokens.isExpired {
            guard tokens.refreshToken != nil else { return false }
            _ = try await refreshAccessToken()
        }

        return true
    }

    func disconnect() async throws {
        try KeychainService.delete(forKey: keychainKey)
    }

    func refreshAccessToken() async throws -> GoogleTokens {
        guard let tokens: GoogleTokens = try KeychainService.loadCodable(forKey: keychainKey, as: GoogleTokens.self),
              let refreshToken = tokens.refreshToken else {
            throw AuthError.tokenExpired
        }

        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type=refresh_token",
            "client_id=\(clientID)",
            "refresh_token=\(refreshToken)"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.tokenExpired
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String,
              let expiresIn = json?["expires_in"] as? Int else {
            throw AuthError.invalidResponse
        }

        let newTokens = GoogleTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn)),
            email: tokens.email
        )

        try KeychainService.saveCodable(newTokens, forKey: keychainKey)
        return newTokens
    }

    private func buildAuthorizationURL(codeChallenge: String) -> URL {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        return components.url!
    }

    @MainActor
    private func performWebAuthentication(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "com.kurapa.timesheetgenerator"
            ) { callbackURL, error in
                if let error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: AuthError.cancelled)
                    } else {
                        continuation.resume(throwing: AuthError.networkError(error.localizedDescription))
                    }
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: AuthError.invalidResponse)
                    return
                }
                continuation.resume(returning: callbackURL)
            }

            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    private func extractAuthorizationCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }

    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws -> GoogleTokens {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type=authorization_code",
            "code=\(code)",
            "client_id=\(clientID)",
            "redirect_uri=\(redirectURI)",
            "code_verifier=\(codeVerifier)"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.invalidCredentials
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String,
              let expiresIn = json?["expires_in"] as? Int else {
            throw AuthError.invalidResponse
        }

        let refreshToken = json?["refresh_token"] as? String

        let userInfo = try await fetchUserInfo(accessToken: accessToken)

        return GoogleTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn)),
            email: userInfo
        )
    }

    private func fetchUserInfo(accessToken: String) async throws -> String {
        let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["email"] as? String ?? "Unknown"
    }

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return verifier }
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
