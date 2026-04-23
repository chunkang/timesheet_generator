# Acceptance Criteria: SPEC-EXPORT-003

## AC-1: CSV Export Content

**Given** a timesheet with 5 entries across 2 days
**When** the user exports as CSV
**Then** the CSV contains a header row plus 5 data rows with correct column values

## AC-2: PDF Export Layout

**Given** a timesheet with entries across a full work week
**When** the user exports as PDF
**Then** the PDF shows a title with the date range, entries grouped by date, and a summary table

## AC-3: Empty Range Warning

**Given** no entries exist for the selected date range
**When** the user attempts to export
**Then** an alert asks "No entries found. Export anyway?" with Cancel and Export buttons

## AC-4: Save Dialog Default Filename

**Given** the user exports for date range Apr 14 to Apr 18
**When** the save dialog appears
**Then** the default filename is `Timesheet_2026-04-14_to_2026-04-18.csv` (or .pdf)

## AC-5: CSV Escaping

**Given** an entry description contains a comma (e.g., "Fix bug, deploy")
**When** exported as CSV
**Then** the field is properly quoted so the CSV is valid
