import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Data Sources")
                    .font(.title2)
                    .fontWeight(.semibold)

                ForEach(DataSourceType.allCases) { sourceType in
                    if let config = viewModel.config(for: sourceType) {
                        DataSourceSettingsRow(
                            sourceType: sourceType,
                            config: config,
                            viewModel: viewModel
                        )
                    }
                }

                Divider()

                UserPreferencesView(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("Settings")
        .task {
            await viewModel.load()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct DataSourceSettingsRow: View {
    let sourceType: DataSourceType
    let config: DataSourceConfig
    @ObservedObject var viewModel: SettingsViewModel

    private var isConnected: Bool {
        config.connectionStatus == .connected
    }

    private var statusColor: Color {
        switch config.connectionStatus {
        case .connected: .green
        case .error: .red
        case .disconnected: .gray
        }
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: sourceType.systemImage)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text(sourceType.rawValue)
                        .font(.headline)

                    Spacer()

                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text(config.connectionStatus.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if isConnected {
                    HStack {
                        if !config.displayName.isEmpty {
                            Text(config.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("Enabled", isOn: Binding(
                            get: { config.isEnabled },
                            set: { newValue in
                                Task { await viewModel.toggleSource(sourceType, isEnabled: newValue) }
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }
                }

                if !isConnected {
                    connectControls
                }

                HStack {
                    Spacer()
                    if isConnected {
                        Button("Disconnect", role: .destructive) {
                            Task { await viewModel.disconnect(source: sourceType) }
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Connect") {
                            Task { await viewModel.connect(source: sourceType) }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isConnecting)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var connectControls: some View {
        switch sourceType {
        case .google:
            EmptyView()
        case .github:
            SecureField("Personal Access Token", text: $viewModel.githubToken)
                .textFieldStyle(.roundedBorder)
        case .jira, .confluence:
            VStack(spacing: 8) {
                TextField("Base URL (e.g., https://myteam.atlassian.net)", text: $viewModel.atlassianBaseURL)
                    .textFieldStyle(.roundedBorder)
                TextField("Email", text: $viewModel.atlassianEmail)
                    .textFieldStyle(.roundedBorder)
                SecureField("API Token", text: $viewModel.atlassianAPIToken)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}
