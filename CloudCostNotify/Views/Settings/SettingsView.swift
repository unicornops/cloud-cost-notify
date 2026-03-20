import SwiftUI

struct SettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        TabView {
            AccountsSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Providers", systemImage: "cloud")
                }

            RefreshSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .frame(width: 560, height: 420)
    }
}

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("App") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.setLaunchAtLogin($0) }
                ))
            }

            Section("Data") {
                Button("Clear Cached Cost Data") {
                    Task {
                        await viewModel.clearCache()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
