import SwiftUI

@MainActor
final class ExportViewModel: ObservableObject {
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -Calendar.current.component(.weekday, from: Date()) + 2, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var selectedFormat: ExportFormat = .csv
    @Published var isExporting = false
    @Published var showEmptyWarning = false
    @Published var exportSuccess: Bool?

    private var entries: [TimesheetEntry] = []

    private let googleCalendar = GoogleCalendarService()
    private let github = GitHubDataService()
    private let jira = JiraDataService()
    private let confluence = ConfluenceDataService()

    func fetchAndExport() async {
        isExporting = true
        exportSuccess = nil

        let adjustedEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        let enabledServices = await getEnabledServices()

        var allEntries: [TimesheetEntry] = []
        await withTaskGroup(of: SourceFetchResult.self) { group in
            for service in enabledServices {
                group.addTask {
                    do {
                        let entries = try await service.fetchActivities(from: self.startDate, to: adjustedEnd)
                        return SourceFetchResult(source: service.sourceType, entries: entries)
                    } catch {
                        return SourceFetchResult(source: service.sourceType, error: error)
                    }
                }
            }
            for await result in group {
                allEntries.append(contentsOf: result.entries)
            }
        }

        entries = allEntries.sorted { $0.date < $1.date }

        if entries.isEmpty {
            showEmptyWarning = true
            isExporting = false
            return
        }

        await performExport()
    }

    func exportAnyway() async {
        showEmptyWarning = false
        await performExport()
    }

    private func performExport() async {
        let filename = ExportService.defaultFilename(from: startDate, to: endDate, format: selectedFormat)

        let data: Data
        switch selectedFormat {
        case .csv:
            let csv = ExportService.generateCSV(entries: entries)
            data = csv.data(using: .utf8) ?? Data()
        case .pdf:
            data = ExportService.generatePDF(entries: entries, from: startDate, to: endDate)
        }

        let success = await ExportService.saveWithPanel(
            data: data,
            defaultName: filename,
            fileExtension: selectedFormat.fileExtension
        )

        exportSuccess = success
        isExporting = false
    }

    private func getEnabledServices() async -> [any DataSourceService] {
        let configs = (try? await PersistenceService.shared.load(from: "data_sources.json", as: [DataSourceConfig].self)) ?? []

        var services: [any DataSourceService] = []
        for config in configs where config.isEnabled && config.connectionStatus == .connected {
            switch config.type {
            case .google: services.append(googleCalendar)
            case .github: services.append(github)
            case .jira: services.append(jira)
            case .confluence: services.append(confluence)
            }
        }
        return services
    }
}
