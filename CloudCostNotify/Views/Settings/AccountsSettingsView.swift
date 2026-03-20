import AppKit
import SwiftUI

struct AccountsSettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                providerOverviewSection
                awsConfigurationSection
                awsProfilesSection
            }
            .padding()
        }
        .task {
            await viewModel.refreshProfiles()
        }
    }

    private var providerOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cloud Providers")
                .font(.title3.weight(.semibold))

            Text(
                "AWS is available now. Azure and Google Cloud are represented in the app " +
                    "structure and UI, but their billing integrations are intentionally not enabled yet."
            )
            .font(.callout)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(viewModel.supportedProviders) { provider in
                    ProviderStatusCard(
                        provider: provider,
                        isAvailable: viewModel.isAvailable(for: provider),
                        isConfigured: provider == .aws ? viewModel.isConfigured : false
                    )
                }
            }
        }
    }

    private var awsConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AWS Access")
                    .font(.headline)

                Spacer()

                if let directoryName = viewModel.awsSharedConfigDirectoryName {
                    Label(directoryName, systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(
                "Select your AWS shared configuration folder, usually `~/.aws`. The app " +
                    "reads the standard `config` and `credentials` files from that folder, " +
                    "which supports both AWS SSO and access-key profiles while remaining sandbox-safe."
            )
            .font(.callout)
            .foregroundStyle(.secondary)

            HStack {
                Button("Choose AWS Folder") {
                    chooseAWSFolder()
                }
                .buttonStyle(.borderedProminent)

                if viewModel.awsSharedConfigDirectoryName != nil {
                    Button("Remove Access") {
                        Task {
                            await viewModel.clearAWSSharedConfigDirectory()
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var awsProfilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AWS Profiles")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.enabledProfileCount) enabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.isConfigured {
                ContentUnavailableView(
                    "AWS Folder Not Selected",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Choose your shared AWS folder before enabling profiles.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else if viewModel.availableProfiles.isEmpty {
                ContentUnavailableView(
                    "No AWS Profiles Found",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text(
                        "Make sure your selected folder contains a valid AWS `config` or `credentials` file."
                    )
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                List {
                    ForEach(viewModel.availableProfiles) { profile in
                        ProfileRowView(profile: profile) { enabled in
                            Task {
                                await viewModel.toggleProfile(profile.name, enabled: enabled)
                            }
                        }
                    }
                }
                .frame(minHeight: 220)

                HStack {
                    Text("Profiles are discovered from the selected AWS folder.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Reload Profiles") {
                        Task {
                            await viewModel.refreshProfiles()
                        }
                    }
                }
            }
        }
    }

    private func chooseAWSFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose AWS Shared Configuration Folder"
        panel.message = "Select the folder that contains your AWS config and credentials files."
        panel.prompt = "Choose Folder"
        panel.showsHiddenFiles = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            try? await viewModel.setAWSSharedConfigDirectory(url)
        }
    }
}

struct ProviderStatusCard: View {
    let provider: CloudProviderType
    let isAvailable: Bool
    let isConfigured: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(provider.rawValue, systemImage: provider.iconName)
                .font(.headline)

            Text(isAvailable ? (isConfigured ? "Connected" : "Ready to connect") : "Coming soon")
                .font(.caption)
                .foregroundStyle(isAvailable ? Color.secondary : Color.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ProfileRowView: View {
    let profile: AWSProfile
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Toggle(isOn: Binding(
                get: { profile.isEnabled },
                set: { onToggle($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .fontWeight(.medium)

                    Text(profile.detailSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
        .padding(.vertical, 2)
    }
}
