# Implementation Plan: SPEC-FOUNDATION-001

## Summary

App Scaffold, Settings, and Credential Management — establish the complete application foundation including Xcode project, MVVM architecture, Settings UI, credential storage, and OAuth authentication flows.

**Estimated Duration:** 10 working days
**Complexity:** Medium-High

---

## Phase 1: Project Scaffold (Days 1-2)

### Tasks

1. **Create Xcode project** with SwiftUI App lifecycle
   - Product name: TimesheetGenerator
   - Bundle ID: com.kurapa.timesheetgenerator
   - Minimum deployment: macOS 14.0
   - Swift 6.0 strict concurrency

2. **Set up directory structure** per architecture plan:
   ```
   TimesheetGenerator/
   ├── App/TimesheetGeneratorApp.swift
   ├── Models/
   ├── ViewModels/
   ├── Views/Settings/, Views/Timesheet/, Views/Export/
   ├── Services/
   └── Resources/
   ```

3. **Implement main navigation** using `NavigationSplitView`:
   - Sidebar with three items: Settings, Timesheet, Export
   - Content area showing the selected view
   - Default selection: Settings (on first launch)

4. **Create placeholder views** for Timesheet and Export areas:
   - TimesheetPlaceholderView with empty state message
   - ExportPlaceholderView with "coming soon" state

### Deliverables
- Buildable Xcode project
- NavigationSplitView with sidebar
- Placeholder views for all three areas

---

## Phase 2: Data Models and Persistence (Days 2-3)

### Tasks

1. **Define SwiftData models:**

   - `DataSourceConfig` — id, type (enum: google/github/confluence/jira), isEnabled, connectionStatus (enum: disconnected/connected/error), lastConnected, displayName
   - `UserPreferences` — workingHoursStart, workingHoursEnd, timeZone, defaultProjectMappings

2. **Define core model (non-persisted):**

   - `TimesheetEntry` — id, date, source, project, description, duration, category, isManuallyEdited

3. **Set up SwiftData ModelContainer** in the App entry point with `DataSourceConfig` and `UserPreferences` schemas

4. **Implement KeychainService:**
   - `save(data: Data, for key: String) throws`
   - `load(for key: String) throws -> Data?`
   - `delete(for key: String) throws`
   - Use Security.framework `SecItemAdd`, `SecItemCopyMatching`, `SecItemUpdate`, `SecItemDelete`
   - Key naming convention: `com.kurapa.timesheetgenerator.{source}.{credential-type}`

### Deliverables
- SwiftData schema and model container
- KeychainService with full CRUD operations
- Unit tests for KeychainService

---

## Phase 3: Settings UI (Days 3-5)

### Tasks

1. **Build SettingsView:**
   - Section for each data source with:
     - Source icon and name
     - Connection status indicator (green dot = connected, gray = disconnected, red = error)
     - Connect/Disconnect button
     - Enable/Disable toggle (only visible when connected)
   - User Preferences section at the bottom

2. **Build DataSourceSettingsRow** (reusable component):
   - Displays source name, status, and actions
   - Connect button triggers auth flow (per source type)
   - Disconnect button clears credentials and resets status

3. **Build UserPreferencesView:**
   - Working hours: start time picker, end time picker
   - Time zone: picker with common time zones
   - Default project mappings: editable list of rules

4. **Implement SettingsViewModel:**
   - `@Observable` class
   - Manages array of `DataSourceConfig` via SwiftData
   - Coordinates auth service calls
   - Updates connection status reactively

### Deliverables
- Complete Settings UI with all data source sections
- User preferences configuration
- SettingsViewModel with SwiftData integration

---

## Phase 4: Authentication Flows (Days 5-8)

### Tasks

1. **Define AuthService protocol:**
   ```swift
   protocol AuthService {
       func authenticate() async throws -> AuthResult
       func validateCredentials() async throws -> Bool
       func disconnect() async throws
   }
   ```

2. **Implement GoogleAuthService:**
   - OAuth 2.0 PKCE flow via `ASWebAuthenticationSession`
   - Scopes: `calendar.readonly`, `gmail.readonly`
   - Custom URL scheme callback: `com.kurapa.timesheetgenerator:/oauth/callback`
   - Token exchange: authorization code → access token + refresh token
   - Token refresh: automatic when access token expires
   - Store tokens in Keychain

3. **Implement GitHubAuthService:**
   - Accept Personal Access Token input
   - Validate via `GET https://api.github.com/user` with token in Authorization header
   - Store token in Keychain
   - Extract and display username from response

4. **Implement AtlassianAuthService:**
   - Accept base URL, email, and API token
   - Validate via `GET {baseUrl}/rest/api/3/myself` with Basic auth (email:token)
   - Shared service for both Jira and Confluence (same credentials)
   - Store base URL, email, and token in Keychain

5. **Wire auth services to SettingsViewModel:**
   - Connect button → call `authenticate()`
   - Update `DataSourceConfig.connectionStatus` based on result
   - Disconnect button → call `disconnect()`, clear Keychain entry, reset status

### Deliverables
- GoogleAuthService with PKCE OAuth
- GitHubAuthService with PAT validation
- AtlassianAuthService with API token validation
- All services storing credentials in Keychain

---

## Phase 5: Integration and Testing (Days 8-10)

### Tasks

1. **Unit Tests:**
   - KeychainService: store, retrieve, update, delete operations
   - SettingsViewModel: connect, disconnect, toggle, preference persistence
   - Auth services: mock URLSession responses, verify token storage

2. **UI Tests:**
   - Launch app → verify sidebar navigation
   - Navigate to Settings → verify all source sections visible
   - Connect a source (mocked) → verify status changes to Connected
   - Toggle source off → verify toggle state persists after view reload
   - Set preferences → verify persistence

3. **Integration Verification:**
   - Build and launch the app
   - Verify empty state in Timesheet View
   - Verify navigation between all three areas
   - Verify Keychain operations work with entitlements

4. **Documentation:**
   - Update README with setup instructions (Google Cloud Console, GitHub token)
   - Add entitlements file documentation

### Deliverables
- Unit test suite with >80% coverage on services and view models
- UI test suite for Settings flow
- Updated README with setup instructions

---

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Google OAuth PKCE complexity | Medium | High | Reference Apple's ASWebAuthenticationSession docs; test with real Google Cloud project early |
| Keychain entitlements misconfiguration | Medium | Medium | Test on non-sandboxed build first, then add sandbox entitlements incrementally |
| SwiftData migration issues | Low | Medium | Keep schema simple; avoid complex relationships in v1 |
| Atlassian API changes | Low | Low | Pin to REST API v3; monitor deprecation notices |
| Token refresh race conditions | Medium | Medium | Use actor-based auth service for thread-safe token management |

---

## Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | Swift | 6.0+ |
| UI Framework | SwiftUI | macOS 14+ |
| Persistence | SwiftData | macOS 14+ |
| Credential Storage | Security.framework (Keychain) | System |
| OAuth | AuthenticationServices (ASWebAuthenticationSession) | System |
| Networking | Foundation URLSession | System |
| Testing | XCTest + Swift Testing | Xcode 16+ |
