import SwiftUI

struct TimesheetSummaryView: View {
    @ObservedObject var viewModel: TimesheetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.title3)
                .fontWeight(.semibold)

            GroupBox("Total") {
                Text(String(format: "%.1f hours", viewModel.totalHours))
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            GroupBox("By Source") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.hoursBySource, id: \.source) { item in
                        HStack {
                            Image(systemName: item.source.systemImage)
                                .foregroundStyle(colorForSource(item.source))
                                .frame(width: 20)
                            Text(item.source.rawValue)
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.1f hrs", item.hours))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }

                    if viewModel.hoursBySource.isEmpty {
                        Text("No data")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GroupBox("By Day") {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.entriesByDate, id: \.date) { dateGroup in
                        HStack {
                            Text(shortDate(dateGroup.entries.first?.date))
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.1f hrs", viewModel.hoursForDate(dateGroup.date)))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }

                    if viewModel.entriesByDate.isEmpty {
                        Text("No data")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private func shortDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
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
