# Technology Stack

## Primary Language

**Swift** — Apple's language for native macOS development.

## Framework

**SwiftUI** — Declarative UI framework for building native macOS interfaces with reactive data binding.

## Platform

- **Target:** macOS only (native Mac app)
- **Minimum Deployment Target:** macOS 14.0+ (Sonoma) — recommended for latest SwiftUI features
- **Distribution:** Direct download or Mac App Store

## Key Dependencies (Planned)

| Dependency | Purpose |
|-----------|---------|
| Foundation / URLSession | HTTP networking for API calls |
| SwiftData or Core Data | Local persistence for cached entries and settings |
| AuthenticationServices | OAuth flow for Google, GitHub |
| KeychainAccess or Security.framework | Secure storage of API tokens and credentials |
| PDFKit | PDF report generation |

## External APIs

| Service | API | Auth Method |
|---------|-----|-------------|
| Google Workspace | Google Calendar API, Gmail API | OAuth 2.0 |
| GitHub | GitHub REST/GraphQL API | Personal Access Token or OAuth App |
| Confluence | Atlassian REST API | API Token + Email |
| Jira | Atlassian REST API | API Token + Email |

## Build System

- **Xcode** — Primary IDE and build tool
- **Swift Package Manager (SPM)** — Dependency management
- **xcodebuild** — Command-line builds and CI

## Development Environment

- Xcode 16+
- macOS 15+ (for development)
- Swift 6.0+

## Testing

- XCTest — Unit and UI testing framework
- Swift Testing — Modern test framework (Swift 6)
