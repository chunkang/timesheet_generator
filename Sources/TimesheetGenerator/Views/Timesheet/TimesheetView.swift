import SwiftUI

struct TimesheetView: View {
    @StateObject private var viewModel = TimesheetViewModel()

    var body: some View {
        VStack(spacing: 0) {
            dateRangeBar

            if !viewModel.sourceErrors.isEmpty {
                errorBanner
            }

            if viewModel.isLoading {
                Spacer()
                ProgressView("Fetching activities...")
                Spacer()
            } else if viewModel.allEntries.isEmpty {
                emptyState
            } else {
                HSplitView {
                    entryList
                        .frame(minWidth: 400)
                    TimesheetSummaryView(viewModel: viewModel)
                        .frame(minWidth: 200, maxWidth: 250)
                }
            }
        }
        .navigationTitle("Timesheet")
        .task {
            await viewModel.fetchAll()
        }
    }

    private var dateRangeBar: some View {
        HStack(spacing: 16) {
            DatePicker("From", selection: $viewModel.startDate, displayedComponents: .date)
                .frame(width: 200)
            DatePicker("To", selection: $viewModel.endDate, displayedComponents: .date)
                .frame(width: 200)

            Button("Fetch") {
                Task { await viewModel.fetchAll() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            Spacer()

            Text(String(format: "%.1f hrs total", viewModel.totalHours))
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.bar)
    }

    private var errorBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(viewModel.sourceErrors), id: \.key) { source, error in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("\(source.rawValue): \(error)")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.1))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No entries found")
                .font(.title3)
            Text("No activities found for the selected date range.")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var entryList: some View {
        List {
            ForEach(viewModel.entriesByDate, id: \.date) { dateGroup in
                Section {
                    ForEach(dateGroup.entries) { entry in
                        TimesheetEntryRow(entry: entry, viewModel: viewModel)
                    }
                } header: {
                    HStack {
                        Text(dateGroup.date)
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f hrs", viewModel.hoursForDate(dateGroup.date)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct TimesheetEntryRow: View {
    let entry: TimesheetEntry
    @ObservedObject var viewModel: TimesheetViewModel
    @State private var isEditing = false
    @State private var editDescription: String = ""
    @State private var editDurationMinutes: String = ""
    @State private var editCategory: String = ""

    private var displayEntry: TimesheetEntry {
        viewModel.editedEntries[entry.id] ?? entry
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: displayEntry.source.systemImage)
                .foregroundStyle(colorForSource(displayEntry.source))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(displayEntry.description)
                        .font(.body)
                        .lineLimit(2)
                    if displayEntry.isManuallyEdited {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                HStack(spacing: 8) {
                    Text(displayEntry.project)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !displayEntry.category.isEmpty {
                        Text(displayEntry.category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(formatDuration(displayEntry.duration))
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                editDescription = displayEntry.description
                editDurationMinutes = String(format: "%.0f", displayEntry.duration / 60)
                editCategory = displayEntry.category
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $isEditing) {
            editSheet
        }
    }

    private var editSheet: some View {
        VStack(spacing: 16) {
            Text("Edit Entry")
                .font(.headline)

            TextField("Description", text: $editDescription)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Duration (minutes):")
                TextField("Minutes", text: $editDurationMinutes)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }

            TextField("Category", text: $editCategory)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") { isEditing = false }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Save") {
                    let minutes = Double(editDurationMinutes) ?? (displayEntry.duration / 60)
                    Task {
                        await viewModel.updateEntry(
                            entry,
                            description: editDescription,
                            duration: minutes * 60,
                            category: editCategory
                        )
                    }
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func colorForSource(_ source: DataSourceType) -> Color {
        switch source {
        case .google: .blue
        case .github: .purple
        case .jira: .orange
        case .confluence: .green
        }
    }
}
