import SwiftUI

struct AccountsSettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.isConfigured {
                notConfiguredView
            } else if viewModel.availableProfiles.isEmpty {
                noProfilesView
            } else {
                profileListView
            }
        }
        .padding()
        .task {
            await viewModel.refreshProfiles()
        }
    }

    private var notConfiguredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("AWS credentials not found")
                .font(.headline)

            Text("Create a credentials file at ~/.aws/credentials to get started.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let url = URL(string: "https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html") {
                Link("Learn more about AWS credentials", destination: url)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noProfilesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No profiles found")
                .font(.headline)

            Text("Add profiles to your ~/.aws/credentials file.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Refresh") {
                Task {
                    await viewModel.refreshProfiles()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var profileListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AWS Profiles")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.enabledProfileCount) enabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            List {
                ForEach(viewModel.availableProfiles) { profile in
                    ProfileRowView(profile: profile) { enabled in
                        Task {
                            await viewModel.toggleProfile(profile.name, enabled: enabled)
                        }
                    }
                }
            }
            .listStyle(.bordered)

            HStack {
                Button("Refresh Profiles") {
                    Task {
                        await viewModel.refreshProfiles()
                    }
                }

                Spacer()

                Text("Profiles from ~/.aws/credentials")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .fontWeight(.medium)

                    if let region = profile.region {
                        Text("Region: \(region)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toggleStyle(.checkbox)
        }
    }
}
