import Foundation
import Security

enum KeychainError: LocalizedError, Sendable {
    case duplicateItem
    case itemNotFound
    case unexpectedStatus(OSStatus)
    case dataConversionError

    var errorDescription: String? {
        switch self {
        case .duplicateItem: "Item already exists in Keychain"
        case .itemNotFound: "Item not found in Keychain"
        case .unexpectedStatus(let status): "Keychain error: \(status)"
        case .dataConversionError: "Failed to convert data"
        }
    }
}

struct KeychainService: Sendable {
    private static let serviceName = "com.kurapa.timesheetgenerator"

    static func save(data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try update(data: data, forKey: key)
            return
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    static func load(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        return result as? Data
    }

    static func update(data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    static func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecItemNotFound {
            return
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    static func saveString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        try save(data: data, forKey: key)
    }

    static func loadString(forKey key: String) throws -> String? {
        guard let data = try load(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func saveCodable<T: Codable & Sendable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        try save(data: data, forKey: key)
    }

    static func loadCodable<T: Codable & Sendable>(forKey key: String, as type: T.Type) throws -> T? {
        guard let data = try load(forKey: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
}
