import Foundation

enum DataSourceType: String, Codable, CaseIterable, Identifiable, Sendable {
    case google = "Google Workspace"
    case github = "GitHub"
    case confluence = "Confluence"
    case jira = "Jira"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .google: "calendar"
        case .github: "chevron.left.forwardslash.chevron.right"
        case .confluence: "doc.text"
        case .jira: "checklist"
        }
    }

    var keychainKeyPrefix: String {
        switch self {
        case .google: "com.kurapa.timesheetgenerator.google"
        case .github: "com.kurapa.timesheetgenerator.github"
        case .confluence: "com.kurapa.timesheetgenerator.confluence"
        case .jira: "com.kurapa.timesheetgenerator.jira"
        }
    }
}

enum ConnectionStatus: String, Codable, Sendable {
    case disconnected
    case connected
    case error
}
