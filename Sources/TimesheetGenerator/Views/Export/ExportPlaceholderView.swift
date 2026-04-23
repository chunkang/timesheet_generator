import SwiftUI

struct ExportPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Export")
                .font(.title)
            Text("Export functionality will be available in a future update.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Export")
    }
}
