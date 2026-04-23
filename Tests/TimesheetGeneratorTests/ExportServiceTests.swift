import Foundation
import Testing
@testable import TimesheetGenerator

@Suite("ExportService Tests")
struct ExportServiceTests {
    private func sampleEntries() -> [TimesheetEntry] {
        let cal = Calendar.current
        let monday = cal.date(from: DateComponents(year: 2026, month: 4, day: 20, hour: 9))!
        let tuesday = cal.date(from: DateComponents(year: 2026, month: 4, day: 21, hour: 10))!

        return [
            TimesheetEntry(date: monday, source: .google, project: "Team Calendar", description: "Sprint Planning", duration: 3600, category: "Meeting"),
            TimesheetEntry(date: monday, source: .github, project: "timesheet_generator", description: "Fix build issue", duration: 1800, category: "Development"),
            TimesheetEntry(date: monday, source: .jira, project: "PROJ", description: "PROJ-123: Update API", duration: 7200, category: "Development"),
            TimesheetEntry(date: tuesday, source: .google, project: "Team Calendar", description: "Daily Standup", duration: 900, category: "Meeting"),
            TimesheetEntry(date: tuesday, source: .confluence, project: "Engineering", description: "Architecture Decision Record", duration: 1800, category: "Documentation"),
        ]
    }

    @Test func csvHasHeaderRow() {
        let csv = ExportService.generateCSV(entries: sampleEntries())
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.first == "Date,Source,Project,Description,Duration (hours),Category")
    }

    @Test func csvHasCorrectRowCount() {
        let csv = ExportService.generateCSV(entries: sampleEntries())
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 6) // 1 header + 5 data rows
    }

    @Test func csvEscapesCommas() {
        let entry = TimesheetEntry(
            date: Date(),
            source: .github,
            project: "repo",
            description: "Fix bug, deploy",
            duration: 3600,
            category: "Dev"
        )
        let csv = ExportService.generateCSV(entries: [entry])
        let lines = csv.components(separatedBy: "\n")
        #expect(lines[1].contains("\"Fix bug, deploy\""))
    }

    @Test func csvEscapesQuotes() {
        let entry = TimesheetEntry(
            date: Date(),
            source: .jira,
            project: "PROJ",
            description: "Update \"legacy\" code",
            duration: 1800
        )
        let csv = ExportService.generateCSV(entries: [entry])
        #expect(csv.contains("\"Update \"\"legacy\"\" code\""))
    }

    @Test func csvDurationInHours() {
        let entry = TimesheetEntry(
            date: Date(),
            source: .google,
            project: "Cal",
            description: "Meeting",
            duration: 5400 // 1.5 hours
        )
        let csv = ExportService.generateCSV(entries: [entry])
        #expect(csv.contains("1.50"))
    }

    @Test func csvEmptyEntries() {
        let csv = ExportService.generateCSV(entries: [])
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 1) // header only
    }

    @Test func defaultFilenameCSV() {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2026, month: 4, day: 14))!
        let end = cal.date(from: DateComponents(year: 2026, month: 4, day: 18))!
        let filename = ExportService.defaultFilename(from: start, to: end, format: .csv)
        #expect(filename == "Timesheet_2026-04-14_to_2026-04-18.csv")
    }

    @Test func defaultFilenamePDF() {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2026, month: 4, day: 14))!
        let end = cal.date(from: DateComponents(year: 2026, month: 4, day: 18))!
        let filename = ExportService.defaultFilename(from: start, to: end, format: .pdf)
        #expect(filename == "Timesheet_2026-04-14_to_2026-04-18.pdf")
    }

    @Test func pdfGeneratesNonEmptyData() {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2026, month: 4, day: 20))!
        let end = cal.date(from: DateComponents(year: 2026, month: 4, day: 21))!

        let data = ExportService.generatePDF(entries: sampleEntries(), from: start, to: end)
        #expect(data.count > 0)
    }

    @Test func pdfStartsWithPDFHeader() {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2026, month: 4, day: 20))!
        let end = cal.date(from: DateComponents(year: 2026, month: 4, day: 21))!

        let data = ExportService.generatePDF(entries: sampleEntries(), from: start, to: end)
        let prefix = String(data: data.prefix(5), encoding: .ascii)
        #expect(prefix == "%PDF-")
    }
}
