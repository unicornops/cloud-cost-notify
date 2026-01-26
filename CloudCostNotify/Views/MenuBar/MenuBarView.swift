import SwiftUI

struct MenuBarView: View {
    let viewModel: MenuBarViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection

            Divider()
                .padding(.vertical, 8)

            if !viewModel.isConfigured {
                notConfiguredSection
            } else if !viewModel.hasEnabledAccounts {
                noAccountsSection
            } else if viewModel.hasError {
                errorSection
            } else {
                costBreakdownSection
            }

            Divider()
                .padding(.vertical, 8)

            footerSection
        }
        .padding()
        .frame(width: 320)
        .task {
            await viewModel.initialize()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Cloud Costs")
                    .font(.headline)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            HStack {
                Text("Month to Date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(viewModel.displayCost)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        }
    }

    private var notConfiguredSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("AWS credentials not found")
                .font(.headline)

            Text("Create ~/.aws/credentials file to get started")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var noAccountsSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No accounts enabled")
                .font(.headline)

            Text("Enable AWS profiles in Settings")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Open Settings") {
                openSettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var errorSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.red)

            Text("Error fetching costs")
                .font(.headline)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var costBreakdownSection: some View {
        CostBreakdownView(costData: viewModel.costData)
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let nextRefresh = viewModel.nextRefresh {
                    Text("Next: \(nextRefresh)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)

                Spacer()

                Button {
                    openSettings()
                } label: {
                    Label("Settings", systemImage: "gear")
                }

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
            }
            .buttonStyle(.borderless)
        }
    }
}
