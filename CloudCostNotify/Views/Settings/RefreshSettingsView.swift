import SwiftUI

struct RefreshSettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Picker("Refresh Interval", selection: Binding(
                    get: { viewModel.selectedRefreshInterval },
                    set: { interval in
                        Task {
                            await viewModel.setRefreshInterval(interval)
                        }
                    }
                )) {
                    ForEach(RefreshScheduler.RefreshInterval.allCases) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Automatic Refresh")
            } footer: {
                Text(
                    "Cloud costs are updated periodically. " +
                        "More frequent refreshes may incur additional API costs ($0.01 per request)."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Current Interval", value: viewModel.selectedRefreshInterval.displayName)
            } header: {
                Text("Status")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
