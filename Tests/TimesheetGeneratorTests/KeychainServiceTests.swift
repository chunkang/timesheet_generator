import Foundation
import Testing
@testable import TimesheetGenerator

@Suite("KeychainService Tests", .serialized)
struct KeychainServiceTests {
    @Test func saveAndLoadString() throws {
        let key = "com.kurapa.timesheetgenerator.test.saveload"
        defer { try? KeychainService.delete(forKey: key) }

        try KeychainService.saveString("test-value", forKey: key)
        let loaded = try KeychainService.loadString(forKey: key)
        #expect(loaded == "test-value")
    }

    @Test func loadNonexistentKey() throws {
        let loaded = try KeychainService.loadString(forKey: "com.kurapa.timesheetgenerator.nonexistent.\(UUID())")
        #expect(loaded == nil)
    }

    @Test func updateExistingKey() throws {
        let key = "com.kurapa.timesheetgenerator.test.update"
        defer { try? KeychainService.delete(forKey: key) }

        try KeychainService.saveString("original", forKey: key)
        try KeychainService.saveString("updated", forKey: key)
        let loaded = try KeychainService.loadString(forKey: key)
        #expect(loaded == "updated")
    }

    @Test func deleteKey() throws {
        let key = "com.kurapa.timesheetgenerator.test.delete"
        try KeychainService.saveString("to-delete", forKey: key)
        try KeychainService.delete(forKey: key)
        let loaded = try KeychainService.loadString(forKey: key)
        #expect(loaded == nil)
    }

    @Test func deleteNonexistentKeyDoesNotThrow() throws {
        try KeychainService.delete(forKey: "com.kurapa.timesheetgenerator.test.noop.\(UUID())")
    }

    @Test func saveCodableAndLoad() throws {
        let key = "com.kurapa.timesheetgenerator.test.codable"
        defer { try? KeychainService.delete(forKey: key) }

        let credentials = AtlassianCredentials(
            baseURL: "https://test.atlassian.net",
            email: "test@example.com",
            apiToken: "token123"
        )

        try KeychainService.saveCodable(credentials, forKey: key)
        let loaded = try KeychainService.loadCodable(forKey: key, as: AtlassianCredentials.self)

        #expect(loaded?.baseURL == "https://test.atlassian.net")
        #expect(loaded?.email == "test@example.com")
        #expect(loaded?.apiToken == "token123")
    }
}
