import SwiftUI

@MainActor
final class TimesheetViewModel: ObservableObject {
    @Published var entries: [TimesheetEntry] = []
    @Published var editedEntries: [UUID: TimesheetEntry] = [:]
    @Published var isLoading = false
    @Published var sourceErrors: [DataSourceType: String] = [:]
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -Calendar.current.component(.weekday, from: Date()) + 2, to: Date()) ?? Date()
    @Published var endDate: Date = Date()

    private let googleCalendar = GoogleCalendarService()
    private let github = GitHubDataService()
    private let jira = JiraDataService()
    private let confluence = ConfluenceDataService()

    private let editsFile = "edited_entries.json"

    var allEntries: [TimesheetEntry] {
        entries.map { entry in
            editedEntries[entry.id] ?? entry
        }
    }

    var entriesByDate: [(date: String, entries: [TimesheetEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .full

        let grouped = Dictionary(grouping: allEntries) { entry -> String in
            formatter.string(from: entry.date)
        }

        return grouped.sorted { pair1, pair2 in
            guard let d1 = pair1.value.first?.date, let d2 = pair2.value.first?.date else { return false }
            return d1 < d2
        }.map { (date: $0.key, entries: $0.value) }
    }

    var totalHours: Double {
        allEntries.reduce(0) { $0 + $1.duration } / 3600
    }

    var hoursBySource: [(source: DataSourceType, hours: Double)] {
        let grouped = Dictionary(grouping: allEntries) { $0.source }
        return grouped.map { (source: $0.key, hours: $0.value.reduce(0) { $0 + $1.duration } / 3600) }
            .sorted { $0.hours > $1.hours }
    }

    func hoursForDate(_ dateString: String) -> Double {
        entriesByDate.first(where: { $0.date == dateString })?.entries
            .reduce(0) { $0 + $1.duration / 3600 } ?? 0
    }

    func fetchAll() async {
        isLoading = true
        sourceErrors = [:]

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
                if let error = result.error {
                    sourceErrors[result.source] = error.localizedDescription
                }
            }
        }

        entries = allEntries.sorted { $0.date < $1.date }

        await loadEdits()
        isLoading = false
    }

    func updateEntry(_ entry: TimesheetEntry, description: String? = nil, duration: TimeInterval? = nil, category: String? = nil) async {
        var edited = editedEntries[entry.id] ?? entry
        if let description { edited = TimesheetEntry(id: edited.id, date: edited.date, source: edited.source, project: edited.project, description: description, duration: edited.duration, category: edited.category, isManuallyEdited: true) }
        if let duration { edited = TimesheetEntry(id: edited.id, date: edited.date, source: edited.source, project: edited.project, description: edited.description, duration: duration, category: edited.category, isManuallyEdited: true) }
        if let category { edited = TimesheetEntry(id: edited.id, date: edited.date, source: edited.source, project: edited.project, description: edited.description, duration: edited.duration, category: category, isManuallyEdited: true) }

        editedEntries[entry.id] = edited
        await saveEdits()
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

    private func saveEdits() async {
        let codableEdits = editedEntries.mapValues { CodableTimesheetEntry(from: $0) }
        try? await PersistenceService.shared.save(codableEdits, to: editsFile)
    }

    private func loadEdits() async {
        guard let saved = try? await PersistenceService.shared.load(from: editsFile, as: [UUID: CodableTimesheetEntry].self) else { return }
        editedEntries = saved.compactMapValues { $0.toTimesheetEntry() }
    }
}

private struct CodableTimesheetEntry: Codable {
    let id: UUID
    let date: Date
    let sourceRawValue: String
    let project: String
    let description: String
    let duration: TimeInterval
    let category: String

    init(from entry: TimesheetEntry) {
        id = entry.id
        date = entry.date
        sourceRawValue = entry.source.rawValue
        project = entry.project
        description = entry.description
        duration = entry.duration
        category = entry.category
    }

    func toTimesheetEntry() -> TimesheetEntry? {
        guard let source = DataSourceType(rawValue: sourceRawValue) else { return nil }
        return TimesheetEntry(id: id, date: date, source: source, project: project, description: description, duration: duration, category: category, isManuallyEdited: true)
    }
}
