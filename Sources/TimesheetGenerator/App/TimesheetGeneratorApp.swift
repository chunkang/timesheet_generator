import SwiftUI

@main
struct TimesheetGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: SidebarItem? = .settings

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedTab)
        } detail: {
            switch selectedTab {
            case .settings:
                SettingsView()
            case .timesheet:
                TimesheetView()
            case .export:
                ExportPlaceholderView()
            case nil:
                Text("Select an item from the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case settings = "Settings"
    case timesheet = "Timesheet"
    case export = "Export"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .settings: "gear"
        case .timesheet: "clock"
        case .export: "square.and.arrow.up"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.systemImage)
                .tag(item)
        }
        .navigationTitle("Timesheet Generator")
    }
}
