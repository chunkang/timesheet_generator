import Foundation

struct DataSourceConfig: Codable, Identifiable, Sendable {
    let type: DataSourceType
    var isEnabled: Bool
    var connectionStatus: ConnectionStatus
    var lastConnected: Date?
    var displayName: String

    var id: String { type.rawValue }

    init(type: DataSourceType, isEnabled: Bool = false, connectionStatus: ConnectionStatus = .disconnected, displayName: String = "") {
        self.type = type
        self.isEnabled = isEnabled
        self.connectionStatus = connectionStatus
        self.displayName = displayName
    }
}
