# Project Structure

## Architecture Pattern

MVVM (Model-View-ViewModel) — standard pattern for SwiftUI applications.

## Directory Layout (Planned)

```
timesheet_generator/
├── TimesheetGenerator/               # Main app target
│   ├── App/                          # App entry point, app lifecycle
│   │   └── TimesheetGeneratorApp.swift
│   ├── Models/                       # Data models
│   │   ├── TimesheetEntry.swift      # Core timesheet entry model
│   │   ├── DataSource.swift          # Data source configuration model
│   │   └── ExportFormat.swift        # Export format definitions
│   ├── ViewModels/                   # View models (business logic)
│   │   ├── SettingsViewModel.swift
│   │   ├── TimesheetViewModel.swift
│   │   └── ExportViewModel.swift
│   ├── Views/                        # SwiftUI views
│   │   ├── Settings/                 # Settings configuration screens
│   │   ├── Timesheet/                # Timesheet display views
│   │   └── Export/                   # Export menu and options
│   ├── Services/                     # API integrations
│   │   ├── GoogleService.swift       # Google Workspace API client
│   │   ├── GitHubService.swift       # GitHub API client
│   │   ├── ConfluenceService.swift   # Confluence API client
│   │   └── JiraService.swift         # Jira API client
│   └── Resources/                    # Assets, localization
├── TimesheetGeneratorTests/          # Unit tests
├── TimesheetGeneratorUITests/        # UI tests
└── Package.swift or .xcodeproj      # Build configuration
```

## Key Module Responsibilities

| Module | Responsibility |
|--------|----------------|
| App | Application entry point, window management, navigation |
| Models | Data structures for timesheet entries, sources, and export formats |
| ViewModels | Business logic, data transformation, state management |
| Views | UI components organized by feature area (Settings, Timesheet, Export) |
| Services | External API communication with each data source |
