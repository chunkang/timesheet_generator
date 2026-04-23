import Foundation

struct UserPreferences: Codable, Sendable {
    var workingHoursStart: DateComponents
    var workingHoursEnd: DateComponents
    var timeZoneIdentifier: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    init(
        workingHoursStart: DateComponents = DateComponents(hour: 9, minute: 0),
        workingHoursEnd: DateComponents = DateComponents(hour: 18, minute: 0),
        timeZoneIdentifier: String = TimeZone.current.identifier
    ) {
        self.workingHoursStart = workingHoursStart
        self.workingHoursEnd = workingHoursEnd
        self.timeZoneIdentifier = timeZoneIdentifier
    }
}
