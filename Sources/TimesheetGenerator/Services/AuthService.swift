import Foundation

struct AuthResult: Sendable {
    let displayName: String
    let email: String?
}

enum AuthError: LocalizedError, Sendable {
    case invalidCredentials
    case networkError(String)
    case cancelled
    case tokenExpired
    case keychainAccessDenied
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: "Invalid credentials. Please check and try again."
        case .networkError(let message): "Network error: \(message)"
        case .cancelled: "Authentication was cancelled."
        case .tokenExpired: "Token has expired. Please reconnect."
        case .keychainAccessDenied: "Unable to access Keychain. Check system permissions."
        case .invalidResponse: "Received an invalid response from the server."
        }
    }
}

protocol AuthServiceProtocol: Sendable {
    func authenticate() async throws -> AuthResult
    func validateCredentials() async throws -> Bool
    func disconnect() async throws
}
