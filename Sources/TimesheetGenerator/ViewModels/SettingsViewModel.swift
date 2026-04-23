import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var dataSources: [DataSourceConfig] = []
    @Published var preferences: UserPreferences = UserPreferences()
    @Published var isConnecting: Bool = false
    @Published var connectingSource: DataSourceType?
    @Published var errorMessage: String?

    @Published var githubToken: String = ""
    @Published var atlassianBaseURL: String = ""
    @Published var atlassianEmail: String = ""
    @Published var atlassianAPIToken: String = ""

    private let googleAuth = GoogleAuthService()
    private let githubAuth = GitHubAuthService()
    private let jiraAuth = AtlassianAuthService(sourceType: .jira)
    private let confluenceAuth = AtlassianAuthService(sourceType: .confluence)

    private let dataSourcesFile = "data_sources.json"
    private let preferencesFile = "preferences.json"

    func load() async {
        dataSources = (try? await PersistenceService.shared.load(from: dataSourcesFile, as: [DataSourceConfig].self)) ?? []

        if dataSources.isEmpty {
            dataSources = DataSourceType.allCases.map { DataSourceConfig(type: $0) }
            await save()
        }

        preferences = (try? await PersistenceService.shared.load(from: preferencesFile, as: UserPreferences.self)) ?? UserPreferences()
    }

    private func save() async {
        try? await PersistenceService.shared.save(dataSources, to: dataSourcesFile)
    }

    func savePreferences() async {
        try? await PersistenceService.shared.save(preferences, to: preferencesFile)
    }

    func config(for type: DataSourceType) -> DataSourceConfig? {
        dataSources.first(where: { $0.type == type })
    }

    private func updateConfig(for type: DataSourceType, _ update: (inout DataSourceConfig) -> Void) async {
        guard let index = dataSources.firstIndex(where: { $0.type == type }) else { return }
        update(&dataSources[index])
        await save()
    }

    func connect(source type: DataSourceType) async {
        isConnecting = true
        connectingSource = type
        errorMessage = nil

        do {
            let result: AuthResult

            switch type {
            case .google:
                result = try await googleAuth.authenticate()
            case .github:
                await githubAuth.setToken(githubToken)
                result = try await githubAuth.authenticate()
                githubToken = ""
            case .jira:
                await jiraAuth.setCredentials(baseURL: atlassianBaseURL, email: atlassianEmail, apiToken: atlassianAPIToken)
                result = try await jiraAuth.authenticate()
                await updateConfig(for: .confluence) { config in
                    if config.connectionStatus == .disconnected {
                        config.connectionStatus = .connected
                        config.displayName = result.displayName
                        config.isEnabled = true
                        config.lastConnected = Date()
                    }
                }
                clearAtlassianInputs()
            case .confluence:
                await confluenceAuth.setCredentials(baseURL: atlassianBaseURL, email: atlassianEmail, apiToken: atlassianAPIToken)
                result = try await confluenceAuth.authenticate()
                await updateConfig(for: .jira) { config in
                    if config.connectionStatus == .disconnected {
                        config.connectionStatus = .connected
                        config.displayName = result.displayName
                        config.isEnabled = true
                        config.lastConnected = Date()
                    }
                }
                clearAtlassianInputs()
            }

            await updateConfig(for: type) { config in
                config.connectionStatus = .connected
                config.displayName = result.displayName
                config.isEnabled = true
                config.lastConnected = Date()
            }
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            await updateConfig(for: type) { config in
                config.connectionStatus = .error
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isConnecting = false
        connectingSource = nil
    }

    func disconnect(source type: DataSourceType) async {
        do {
            switch type {
            case .google: try await googleAuth.disconnect()
            case .github: try await githubAuth.disconnect()
            case .jira: try await jiraAuth.disconnect()
            case .confluence: try await confluenceAuth.disconnect()
            }

            await updateConfig(for: type) { config in
                config.connectionStatus = .disconnected
                config.isEnabled = false
                config.displayName = ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSource(_ type: DataSourceType, isEnabled: Bool) async {
        await updateConfig(for: type) { config in
            config.isEnabled = isEnabled
        }
    }

    private func clearAtlassianInputs() {
        atlassianBaseURL = ""
        atlassianEmail = ""
        atlassianAPIToken = ""
    }
}
