---
id: SPEC-AGGREGATION-002
version: "1.0.0"
status: "draft"
created: "2026-04-23"
updated: "2026-04-23"
author: "Chun Kang"
priority: "HIGH"
---

## HISTORY

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-04-23 | Chun Kang | Initial SPEC creation |

---

# SPEC-AGGREGATION-002: Multi-Source Data Fetching and Timesheet View

## Overview

Implement four API service clients (Google Calendar, GitHub, Confluence, Jira) and the Timesheet View that aggregates, normalizes, and displays work entries by date. Includes date-range-based fetching, activity-to-timesheet-entry mapping, grouping/filtering, manual editing, and summary statistics.

---

## Requirements (EARS Format)

### R1: Event-driven — Date Range Fetch

WHEN the user selects a date range in the Timesheet View, THEN the system SHALL fetch activities from all enabled data sources for that date range concurrently using Swift concurrency (async/await).

### R2: Ubiquitous — DataSourceService Protocol

Each API service client SHALL implement a common `DataSourceService` protocol with a `fetchActivities(from: Date, to: Date) async throws -> [TimesheetEntry]` method.

### R3: Event-driven — Google Calendar Mapping

WHEN Google Calendar data is fetched, THEN the system SHALL map calendar events to timesheet entries using event title as description, event duration as time logged, and calendar name as project.

### R4: Event-driven — GitHub Activity Mapping

WHEN GitHub data is fetched, THEN the system SHALL aggregate commits (by repository/date), pull request activity, and code review activity into timesheet entries.

### R5: Event-driven — Jira Activity Mapping

WHEN Jira data is fetched, THEN the system SHALL include issue transitions, time logged via worklogs, and comments as timesheet entries.

### R6: Event-driven — Confluence Activity Mapping

WHEN Confluence data is fetched, THEN the system SHALL include page creations, edits, and comments as timesheet entries.

### R7: Ubiquitous — Grouped Display

The Timesheet View SHALL display entries grouped by date, with sub-grouping options for source, project, or category.

### R8: Event-driven — Manual Entry Editing

WHEN the user edits a timesheet entry (description, duration, or category), THEN the system SHALL persist the edit locally without modifying the source system.

### R9: Ubiquitous — Summary Statistics

The Timesheet View SHALL display summary statistics including total hours per day, total hours for the selected range, and breakdown by source/project.

### R10: Unwanted Behavior — Partial Failure Resilience

IF an API call fails due to rate limiting or network error, THEN the system SHALL display the error for that specific source and continue displaying data from other sources.

---

## Scope

### In Scope

- DataSourceService protocol and four concrete implementations
- Google Calendar API client (event listing by date range)
- GitHub API client (commits, PRs, reviews by date range)
- Jira API client (worklogs, issue transitions by date range)
- Confluence API client (page activity by date range)
- TimesheetView with date range picker, grouped entries, summary stats
- TimesheetViewModel for data aggregation and state management
- Manual entry editing with local persistence
- Concurrent multi-source fetching with partial failure handling

### Out of Scope

- Gmail activity (deferred to future enhancement)
- Real-time sync or webhooks
- Report export (SPEC-EXPORT-003)

---

## Dependencies

- SPEC-FOUNDATION-001 (completed): KeychainService, auth services, DataSourceConfig, TimesheetEntry model
