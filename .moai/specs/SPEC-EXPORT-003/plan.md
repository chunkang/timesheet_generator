# Implementation Plan: SPEC-EXPORT-003

## Summary

Report Export — CSV and PDF export with menu integration and save dialog.

**Estimated Duration:** 2 working days
**Complexity:** Medium

---

## Phase 1: Export Service and CSV Generation

1. Implement `ExportService` with `exportCSV(entries:)` and `exportPDF(entries:dateRange:)`
2. CSV generation with proper escaping and headers

## Phase 2: PDF Generation

1. Build PDF layout using Core Graphics / NSAttributedString
2. Title, date-grouped entries table, summary footer

## Phase 3: Export View and Menu Integration

1. Replace ExportPlaceholderView with ExportView
2. Add File > Export menu command
3. Wire NSSavePanel for file saving
4. Empty range warning alert

## Phase 4: Testing

1. Unit tests for CSV generation
2. Unit tests for PDF content
