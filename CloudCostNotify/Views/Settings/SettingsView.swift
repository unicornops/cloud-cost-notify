import SwiftUI

struct SettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        TabView {
            AccountsSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Accounts", systemImage: "person.2")
                }

            RefreshSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.setLaunchAtLogin($0) }
                ))
            }

            Section {
                Button("Clear Cache") {
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
