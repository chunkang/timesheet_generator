import Foundation
import Testing
@testable import TimesheetGenerator

@Suite("TimesheetEntry Tests")
struct TimesheetEntryTests {
    @Test func createEntry() {
        let date = Date()
        let entry = TimesheetEntry(
            date: date,
            source: .github,
            project: "timesheet_generator",
            description: "Fix build issue",
            duration: 3600,
            category: "Development"
        )

        #expect(entry.source == .github)
        #expect(entry.project == "timesheet_generator")
        #expect(entry.description == "Fix build issue")
        #expect(entry.duration == 3600)
        #expect(entry.category == "Development")
        #expect(entry.isManuallyEdited == false)
    }

    @Test func defaultCategoryIsEmpty() {
        let entry = TimesheetEntry(
            date: Date(),
            source: .jira,
            project: "PROJ",
            description: "Task",
            duration: 1800
        )
        #expect(entry.category == "")
    }

    @Test func entryIdentifiable() {
        let entry1 = TimesheetEntry(date: Date(), source: .google, project: "A", description: "B", duration: 60)
        let entry2 = TimesheetEntry(date: Date(), source: .google, project: "A", description: "B", duration: 60)
        #expect(entry1.id != entry2.id)
    }
}

@Suite("DataSourceConfig Tests")
struct DataSourceConfigTests {
    @Test func defaultValues() {
        let config = DataSourceConfig(type: .github)
        #expect(config.type == .github)
        #expect(config.isEnabled == false)
        #expect(config.connectionStatus == .disconnected)
        #expect(config.displayName == "")
    }

    @Test func encodeDecode() throws {
        let config = DataSourceConfig(type: .jira, isEnabled: true, connectionStatus: .connected, displayName: "Chun")
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(DataSourceConfig.self, from: data)
        #expect(decoded.type == .jira)
        #expect(decoded.isEnabled == true)
        #expect(decoded.connectionStatus == .connected)
        #expect(decoded.displayName == "Chun")
    }
}
