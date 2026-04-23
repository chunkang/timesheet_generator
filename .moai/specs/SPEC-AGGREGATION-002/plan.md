# Implementation Plan: SPEC-AGGREGATION-002

## Summary

Multi-Source Data Fetching and Timesheet View — implement API clients for Google Calendar, GitHub, Jira, and Confluence, plus the Timesheet View with date selection, grouped entries, editing, and summary statistics.

**Estimated Duration:** 5 working days
**Complexity:** High

---

## Phase 1: DataSourceService Protocol and Google Calendar Client

### Tasks

1. Define `DataSourceService` protocol with `fetchActivities(from:to:) async throws -> [TimesheetEntry]`
2. Implement `GoogleCalendarService` — fetch events via Google Calendar API v3, map to TimesheetEntry
3. Load credentials from Keychain using existing GoogleAuthService tokens

---

## Phase 2: GitHub, Jira, Confluence API Clients

### Tasks

1. Implement `GitHubDataService` — fetch commits via `/users/{user}/events`, PRs, reviews
2. Implement `JiraDataService` — fetch worklogs via `/rest/api/3/search`, issue transitions
3. Implement `ConfluenceDataService` — fetch page activity via `/wiki/rest/api/content`

---

## Phase 3: TimesheetViewModel and Aggregation

### Tasks

1. Implement `TimesheetViewModel` — manages date range, coordinates fetching from all enabled sources concurrently
2. Implement partial failure handling — TaskGroup with per-source error capture
3. Implement manual entry editing with local persistence via PersistenceService

---

## Phase 4: Timesheet View UI

### Tasks

1. Build `TimesheetView` — date range picker, loading state, entry list
2. Build `TimesheetEntryRow` — displays individual entries with edit capability
3. Build `TimesheetSummaryView` — daily totals, source breakdown
4. Implement grouping by date with sub-grouping by source/project

---

## Phase 5: Integration and Testing

### Tasks

1. Wire TimesheetView into app navigation (replace placeholder)
2. Add unit tests for data mapping logic
3. Verify concurrent fetch, partial failure, and editing
