import SwiftUI

struct ExportView: View {
    @StateObject private var viewModel = ExportViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Export Timesheet")
                .font(.title)

            GroupBox {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        DatePicker("From", selection: $viewModel.startDate, displayedComponents: .date)
                            .frame(width: 200)
                        DatePicker("To", selection: $viewModel.endDate, displayedComponents: .date)
                            .frame(width: 200)
                    }

                    Picker("Format", selection: $viewModel.selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: 450)

            Button {
                Task { await viewModel.fetchAndExport() }
            } label: {
                HStack {
                    if viewModel.isExporting {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(viewModel.isExporting ? "Exporting..." : "Export")
                }
                .frame(width: 150)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isExporting)

            if let success = viewModel.exportSuccess {
                HStack {
                    Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(success ? .green : .red)
                    Text(success ? "Export saved successfully." : "Export cancelled.")
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Export")
        .alert("No Entries Found", isPresented: $viewModel.showEmptyWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Export Anyway") {
                Task { await viewModel.exportAnyway() }
            }
        } message: {
            Text("No entries found for the selected date range. Export anyway?")
        }
    }
}
