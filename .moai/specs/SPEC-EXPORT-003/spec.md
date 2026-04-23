---
id: SPEC-EXPORT-003
version: "1.0.0"
status: "draft"
created: "2026-04-23"
updated: "2026-04-23"
author: "Chun Kang"
priority: "MEDIUM"
---

## HISTORY

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-04-23 | Chun Kang | Initial SPEC creation |

---

# SPEC-EXPORT-003: Report Export (CSV and PDF)

## Overview

Implement menu-driven export of timesheet reports in CSV and PDF formats. Includes configurable date range, format selection, and macOS NSSavePanel integration.

---

## Requirements (EARS Format)

### R1: Event-driven — Export Menu

WHEN the user selects File > Export from the menu bar, THEN the system SHALL present an export sheet with format and date range options.

### R2: Event-driven — CSV Export

WHEN the user selects CSV export, THEN the system SHALL generate a CSV file with columns: Date, Source, Project, Description, Duration (hours), Category.

### R3: Event-driven — PDF Export

WHEN the user selects PDF export, THEN the system SHALL generate a formatted PDF with a title header, date-grouped entries, and summary totals.

### R4: Event-driven — Save Dialog

WHEN export completes, THEN the system SHALL present a macOS save dialog (NSSavePanel) with default filename `Timesheet_YYYY-MM-DD_to_YYYY-MM-DD.{csv|pdf}`.

### R5: Unwanted Behavior — Empty Range Warning

IF the selected date range contains no entries, THEN the system SHALL warn the user before exporting an empty report.

---

## Dependencies

- SPEC-AGGREGATION-002 (completed): TimesheetViewModel, TimesheetEntry, data fetching
