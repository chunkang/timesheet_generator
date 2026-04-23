import Foundation

struct TimesheetEntry: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let source: DataSourceType
    let project: String
    let description: String
    let duration: TimeInterval
    let category: String
    var isManuallyEdited: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        source: DataSourceType,
        project: String,
        description: String,
        duration: TimeInterval,
        category: String = "",
        isManuallyEdited: Bool = false
    ) {
        self.id = id
        self.date = date
        self.source = source
        self.project = project
        self.description = description
        self.duration = duration
        self.category = category
        self.isManuallyEdited = isManuallyEdited
    }
}
