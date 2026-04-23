---
id: SPEC-FOUNDATION-001
version: "1.0.0"
status: "draft"
created: "2026-04-22"
updated: "2026-04-22"
author: "Chun Kang"
priority: "HIGH"
---

## HISTORY

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-04-22 | Chun Kang | Initial SPEC creation |

---

# SPEC-FOUNDATION-001: App Scaffold, Settings, and Credential Management

## Overview

Establish the Xcode project structure, MVVM skeleton, navigation framework, and the complete Settings module for the Timesheet Generator macOS application. This includes secure credential storage via Keychain, OAuth 2.0 flows for Google Workspace and GitHub, API token management for Atlassian services (Jira/Confluence), and user preference persistence via SwiftData.

This SPEC is the mandatory prerequisite for all subsequent SPECs — no data can be fetched without authenticated API clients and no UI can be built without the application scaffold.

---

## Requirements (EARS Format)

### R1: Ubiquitous — Platform Target

The application SHALL be a native macOS app targeting macOS 14.0+ (Sonoma), built with SwiftUI and Swift 6.0+.

### R2: Ubiquitous — Architecture Pattern

The application SHALL follow MVVM architecture with clear separation between Models, ViewModels, Views, and Services layers.

### R3: Ubiquitous — Credential Security

All API credentials and OAuth tokens SHALL be stored in the macOS Keychain using Security.framework or a KeychainAccess wrapper. Credentials SHALL NOT be stored in plaintext, UserDefaults, or SwiftData.

### R4: Event-driven — Settings View Display

WHEN a user opens the Settings view, THEN the system SHALL display configuration sections for each data source (Google Workspace, GitHub, Confluence, Jira) with their current connection status (Connected/Disconnected).

### R5: Event-driven — Google Workspace OAuth

WHEN a user initiates a Google Workspace connection, THEN the system SHALL launch an OAuth 2.0 authorization flow (PKCE) using ASWebAuthenticationSession, request scopes for Google Calendar and Gmail APIs, and store the resulting access and refresh tokens in the Keychain.

### R6: Event-driven — GitHub Authentication

WHEN a user initiates a GitHub connection, THEN the system SHALL accept a Personal Access Token (or initiate an OAuth App flow), validate it via `GET /user`, display the authenticated username, and store the credential in the Keychain.

### R7: Event-driven — Atlassian Authentication

WHEN a user initiates a Jira or Confluence connection, THEN the system SHALL accept a base URL, API token, and associated email address, validate them against the Atlassian REST API via `GET /rest/api/3/myself`, and store them in the Keychain.

### R8: Event-driven — Source Toggle

WHEN a user toggles a data source off, THEN the system SHALL exclude that source from all subsequent data fetching operations without deleting its stored credentials. The toggle state SHALL persist across app restarts.

### R9: State-driven — Empty State

WHILE no data sources are connected, the Timesheet View SHALL display an empty state view directing the user to the Settings screen.

### R10: Event-driven — User Preferences

WHEN a user configures preferences (working hours start/end, time zone, default project mappings), THEN the system SHALL persist these values using SwiftData and restore them on subsequent app launches.

### R11: Unwanted Behavior — Token Refresh

IF a Google OAuth access token has expired, THEN the system SHALL automatically attempt a token refresh using the stored refresh token before reporting an authentication failure.

### R12: Unwanted Behavior — Invalid Credentials

IF credential validation fails for any data source (network error, invalid token, revoked access), THEN the system SHALL display a specific error message and update the connection status to "Error" without crashing.

---

## Scope

### In Scope

- Xcode project creation with SwiftUI App lifecycle
- Directory structure: App, Models, ViewModels, Views, Services, Resources
- NavigationSplitView with sidebar (Settings, Timesheet, Export)
- SwiftData model container and schema for DataSource, UserPreferences
- Keychain wrapper service (CRUD for credentials)
- Google OAuth 2.0 PKCE flow with token refresh
- GitHub PAT entry and validation
- Atlassian API token entry and validation (shared for Jira and Confluence)
- Settings UI with connection status, connect/disconnect, enable/disable toggle
- User preferences UI (working hours, time zone)
- Placeholder views for Timesheet and Export areas

### Out of Scope

- Actual data fetching from APIs (SPEC-AGGREGATION-002)
- Timesheet entry display and editing (SPEC-AGGREGATION-002)
- Report export functionality (SPEC-EXPORT-003)
- Mac App Store distribution and notarization
- Localization

---

## Technical Constraints

1. **OAuth Redirect URI:** Google OAuth requires a registered custom URL scheme (e.g., `com.kurapa.timesheetgenerator:/oauth/callback`). Must register in Google Cloud Console as "Desktop application" type.
2. **PKCE Requirement:** Google OAuth for installed apps requires PKCE (Proof Key for Code Exchange) — no client secret should be embedded in the app.
3. **Sandbox Restrictions:** If distributing via Mac App Store, app sandbox limits Keychain access scope. Network entitlements must be declared in the entitlements file.
4. **Token Expiry:** Google access tokens expire after 1 hour. The auth service must handle automatic refresh transparently.
5. **Atlassian Cloud vs Server:** Initial implementation targets Atlassian Cloud only (`*.atlassian.net`). Self-hosted Jira/Confluence support is deferred.

---

## Dependencies

| Dependency | Type | Required For |
|-----------|------|-------------|
| Xcode 16+ | Tool | Swift 6.0 and latest SwiftUI features |
| macOS 14.0+ SDK | Platform | SwiftData, latest SwiftUI APIs |
| Google Cloud Console project | External | OAuth client ID registration |
| Security.framework | System | Keychain credential storage |
| AuthenticationServices.framework | System | ASWebAuthenticationSession for OAuth |
| SwiftData | System | Local persistence for preferences and source config |
