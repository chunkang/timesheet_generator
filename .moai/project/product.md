# Product Overview

## Project Name

Timesheet Generator

## Description

A native macOS application that automatically generates timesheets by aggregating work activity data from multiple productivity and development tools. Instead of manually logging hours, users connect their accounts and the app reconstructs a detailed timesheet from real activity.

## Target Audience

- Software engineers and developers who work across multiple tools
- Team leads and project managers who need to report time allocation
- Freelancers and contractors who bill clients based on hours worked

## Core Features

### 1. Multi-Source Data Aggregation

Collects work activity from four integrated sources:

- **Google Workspace** — Calendar events (meetings, focus time), Gmail activity
- **GitHub** — Commits, pull requests, code reviews, issue activity
- **Confluence** — Page creation/edits, comments, space activity
- **Jira** — Issue transitions, time logged, comments, sprint participation

### 2. Settings & Configuration

- API credential management for each data source (OAuth tokens, API keys)
- User-specific settings: default project mappings, working hours, time zone
- Source enable/disable toggles
- Activity categorization rules

### 3. Timesheet View

- Aggregated timeline of work entries organized by date
- Entries grouped by source, project, or category
- Editable entries for manual adjustments
- Summary statistics (total hours, breakdown by source/project)

### 4. Report Export

- Export timesheet reports in multiple formats (CSV, PDF)
- Configurable date ranges for export
- Menu-driven export workflow

## Use Cases

1. **End-of-week reporting** — Generate a weekly timesheet from all connected sources, review, adjust, and export for submission.
2. **Client billing** — Freelancer connects GitHub and Jira, exports a detailed activity report for invoicing.
3. **Manager oversight** — Team lead reviews aggregated activity across tools to understand time allocation.
