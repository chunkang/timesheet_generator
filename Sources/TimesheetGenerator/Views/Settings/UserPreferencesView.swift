import SwiftUI

struct UserPreferencesView: View {
    @ObservedObject var viewModel: SettingsViewModel

    private var startHour: Binding<Double> {
        Binding(
            get: { Double(viewModel.preferences.workingHoursStart.hour ?? 9) },
            set: { newValue in
                viewModel.preferences.workingHoursStart.hour = Int(newValue)
                Task { await viewModel.savePreferences() }
            }
        )
    }

    private var endHour: Binding<Double> {
        Binding(
            get: { Double(viewModel.preferences.workingHoursEnd.hour ?? 18) },
            set: { newValue in
                viewModel.preferences.workingHoursEnd.hour = Int(newValue)
                Task { await viewModel.savePreferences() }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.title2)
                .fontWeight(.semibold)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Working Hours")
                        .font(.headline)

                    HStack(spacing: 16) {
                        HStack {
                            Text("Start:")
                            Picker("", selection: Binding(
                                get: { viewModel.preferences.workingHoursStart.hour ?? 9 },
                                set: {
                                    viewModel.preferences.workingHoursStart.hour = $0
                                    Task { await viewModel.savePreferences() }
                                }
                            )) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(String(format: "%02d:00", hour)).tag(hour)
                                }
                            }
                            .frame(width: 100)
                        }

                        HStack {
                            Text("End:")
                            Picker("", selection: Binding(
                                get: { viewModel.preferences.workingHoursEnd.hour ?? 18 },
                                set: {
                                    viewModel.preferences.workingHoursEnd.hour = $0
                                    Task { await viewModel.savePreferences() }
                                }
                            )) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(String(format: "%02d:00", hour)).tag(hour)
                                }
                            }
                            .frame(width: 100)
                        }
                    }

                    Divider()

                    HStack {
                        Text("Time Zone")
                            .font(.headline)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { viewModel.preferences.timeZoneIdentifier },
                            set: {
                                viewModel.preferences.timeZoneIdentifier = $0
                                Task { await viewModel.savePreferences() }
                            }
                        )) {
                            ForEach(commonTimeZones, id: \.self) { tzID in
                                Text(tzID).tag(tzID)
                            }
                        }
                        .frame(width: 250)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var commonTimeZones: [String] {
        [
            "Asia/Seoul",
            "Asia/Tokyo",
            "Asia/Shanghai",
            "Asia/Singapore",
            "Asia/Kolkata",
            "Europe/London",
            "Europe/Paris",
            "Europe/Berlin",
            "America/New_York",
            "America/Chicago",
            "America/Denver",
            "America/Los_Angeles",
            "Pacific/Auckland",
            "Australia/Sydney"
        ]
    }
}
