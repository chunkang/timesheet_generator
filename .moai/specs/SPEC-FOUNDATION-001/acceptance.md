# Acceptance Criteria: SPEC-FOUNDATION-001

## AC-1: Xcode Project Builds and Launches

**Given** a fresh clone of the repository
**When** the developer runs `xcodebuild -scheme TimesheetGenerator build` or builds from Xcode
**Then** the app compiles without errors, launches, and displays the main window with a NavigationSplitView containing sidebar items: Settings, Timesheet, Export

---

## AC-2: Sidebar Navigation

**Given** the app is running and the main window is visible
**When** the user clicks each sidebar item (Settings, Timesheet, Export)
**Then** the content area updates to show the corresponding view for each selection

---

## AC-3: Google Workspace OAuth Flow

**Given** the user is on the Settings screen and Google Workspace is not connected
**When** the user clicks "Connect Google Workspace" and completes the OAuth consent in the browser
**Then** the Settings view shows Google Workspace as "Connected" with the authenticated email displayed, and the access/refresh tokens are stored in the macOS Keychain

---

## AC-4: Google Token Refresh

**Given** Google Workspace is connected and the access token has expired
**When** the system attempts to use the Google API
**Then** the system automatically refreshes the access token using the stored refresh token without user intervention, and the new token is stored in the Keychain

---

## AC-5: GitHub PAT Authentication

**Given** the user is on the Settings screen and GitHub is not connected
**When** the user enters a valid Personal Access Token and clicks "Connect"
**Then** the system validates the token via `GET https://api.github.com/user`, displays the authenticated GitHub username, and stores the token in the Keychain

---

## AC-6: GitHub Invalid Token Handling

**Given** the user is on the Settings screen and GitHub is not connected
**When** the user enters an invalid Personal Access Token and clicks "Connect"
**Then** the system displays an error message indicating the token is invalid and the connection status remains "Disconnected"

---

## AC-7: Atlassian API Token Validation

**Given** the user is on the Settings screen and Jira is not connected
**When** the user enters a base URL (e.g., `https://myteam.atlassian.net`), email, and API token, then clicks "Connect"
**Then** the system validates credentials via `GET /rest/api/3/myself`, displays the account display name, and stores the credentials in the Keychain

---

## AC-8: Atlassian Shared Credentials

**Given** the user has connected Jira with valid Atlassian credentials
**When** the user views the Confluence connection section
**Then** Confluence shows as "Connected" using the same Atlassian credentials, since Jira and Confluence share the same authentication

---

## AC-9: Source Disconnect

**Given** Google Workspace is connected
**When** the user clicks "Disconnect" for Google Workspace
**Then** the stored credentials are removed from the Keychain, the connection status changes to "Disconnected", and the enable/disable toggle is hidden

---

## AC-10: Source Toggle Persistence

**Given** Google Workspace is connected and enabled
**When** the user toggles Google Workspace off and quits/relaunches the app
**Then** Google Workspace remains connected but disabled (toggle is off), and its data would be excluded from future timesheet aggregation

---

## AC-11: User Preferences Persistence

**Given** the user is on the Settings screen
**When** the user sets working hours to 09:00-18:00 and time zone to Asia/Seoul, then quits and relaunches the app
**Then** the preferences are restored showing working hours 09:00-18:00 and time zone Asia/Seoul

---

## AC-12: Empty State in Timesheet View

**Given** no data sources are connected
**When** the user navigates to the Timesheet View
**Then** an empty state is displayed with a message directing the user to connect data sources in Settings, with a button or link to navigate to Settings

---

## AC-13: Credential Security

**Given** the app has stored OAuth tokens and API keys in the Keychain
**When** inspecting app storage (UserDefaults, SwiftData database, app container files)
**Then** no credentials are found outside the Keychain — all sensitive data is exclusively in Keychain entries

---

## Edge Case Scenarios

### EC-1: Network Unavailable During Auth

**Given** the user attempts to connect a data source
**When** the network is unavailable
**Then** the system displays a network error message and the connection status remains "Disconnected"

### EC-2: OAuth Flow Cancelled

**Given** the user clicks "Connect Google Workspace"
**When** the user closes the OAuth browser window without completing authorization
**Then** the system handles the cancellation gracefully, displays no error, and the status remains "Disconnected"

### EC-3: Concurrent Auth Attempts

**Given** the user clicks "Connect" for Google and GitHub in quick succession
**When** both auth flows are initiated
**Then** each flow completes independently without interfering with the other

### EC-4: Keychain Access Denied

**Given** the app attempts to access the Keychain
**When** macOS denies Keychain access (e.g., due to sandbox misconfiguration)
**Then** the system displays a specific error message about Keychain access and does not crash

---

## Quality Gates

| Gate | Criteria | Target |
|------|----------|--------|
| Build | Project compiles without errors or warnings | Zero errors, zero warnings |
| Unit Test Coverage | Services and ViewModels covered | >80% line coverage |
| UI Test | Settings flow end-to-end | All AC scenarios pass |
| Security | No credentials in plaintext storage | Keychain-only verified |
| Performance | App launch to Settings view | <2 seconds on M1 Mac |
