# Acceptance Criteria: SPEC-AGGREGATION-002

## AC-1: Concurrent Multi-Source Fetch

**Given** Google Workspace and GitHub are connected and enabled
**When** the user views the current week's timesheet
**Then** both sources fetch concurrently and combined entries appear

---

## AC-2: Entry Grouping by Date

**Given** activities exist on 3 different days
**When** the Timesheet View loads
**Then** entries are grouped under date headers in chronological order

---

## AC-3: Manual Entry Editing

**Given** a timesheet entry shows "Team standup" for 30 minutes
**When** the user edits the duration to 45 minutes
**Then** the entry persists as 45 minutes and the daily total updates accordingly

---

## AC-4: Partial Failure Resilience

**Given** Jira credentials have expired but GitHub is valid
**When** the user fetches timesheet data
**Then** GitHub entries display normally and a non-blocking error banner shows the Jira authentication issue

---

## AC-5: Summary Statistics Accuracy

**Given** 3 calendar events (1h each) and 2 Jira worklogs (2h each) exist for Monday
**When** the user views Monday's timesheet
**Then** the daily total shows 7 hours and the source breakdown shows Google: 3h, Jira: 4h

---

## AC-6: Date Range Selection

**Given** the Timesheet View is open
**When** the user selects a custom date range (e.g., Apr 14 to Apr 18)
**Then** only entries within that range are fetched and displayed

---

## AC-7: Empty Date Range

**Given** no activity exists for the selected date range
**When** the Timesheet View loads
**Then** an empty state is displayed with a message indicating no entries found

---

## AC-8: Google Calendar Event Mapping

**Given** a Google Calendar event "Sprint Planning" exists for 1 hour
**When** the data is fetched
**Then** a TimesheetEntry is created with description "Sprint Planning", duration 3600s, source Google, project set to calendar name

---

## AC-9: GitHub Commit Aggregation

**Given** the user made 5 commits to repo "timesheet_generator" on Monday
**When** the data is fetched
**Then** a TimesheetEntry is created for that repo/day with description summarizing the commits

---

## AC-10: Jira Worklog Mapping

**Given** a Jira worklog of 2 hours exists on issue "PROJ-123"
**When** the data is fetched
**Then** a TimesheetEntry is created with duration 7200s, project "PROJ", description referencing PROJ-123
