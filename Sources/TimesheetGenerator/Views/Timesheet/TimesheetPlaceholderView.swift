import SwiftUI

struct TimesheetPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Data Sources Connected")
                .font(.title2)
            Text("Connect your data sources in Settings to start generating timesheets.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Timesheet")
    }
}
