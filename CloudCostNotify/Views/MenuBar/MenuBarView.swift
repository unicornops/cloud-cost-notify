import AppKit
import SwiftUI

struct MenuBarView: View {
    let viewModel: MenuBarViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            summarySection

            if let errorMessage = viewModel.errorMessage, !viewModel.costData.isEmpty {
                warningBanner(message: errorMessage)
            }

            Group {
                if !viewModel.isConfigured {
                    onboardingSection
                } else if !viewModel.hasEnabledAccounts {
                    emptySelectionSection
                } else if viewModel.hasError && viewModel.costData.isEmpty {
                    blockingErrorSection
                } else {
                    CostBreakdownView(costData: viewModel.costData)
                }
            }

            footerSection
        }
        .padding(16)
        .frame(width: 400)
        .task {
            await viewModel.initialize()
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cloud Spend")
                        .font(.headline)

                    Text("Month to date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.displayCost)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(viewModel.supportedProviders) { provider in
                        Text(provider.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(provider.supportsCostFetching ? .blue.opacity(0.12) : .secondary.opacity(0.12),
                                        in: Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var onboardingSection: some View {
        contentSection(
            title: "Connect AWS to get started",
            systemImage: "externaldrive.badge.plus",
            message:
                "Choose your shared AWS configuration folder in Settings. That supports " +
                "both AWS SSO profiles and access-key profiles while keeping App Sandbox enabled."
        ) {
            Button("Open Settings") {
                openSettings()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptySelectionSection: some View {
        contentSection(
            title: "No AWS profiles enabled",
            systemImage: "slider.horizontal.3",
            message: "Turn on one or more AWS profiles in Settings to see spend by account and resource type."
        ) {
            Button("Open Settings") {
                openSettings()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var blockingErrorSection: some View {
        contentSection(
            title: "Unable to load costs",
            systemImage: "exclamationmark.triangle",
            message: viewModel.errorMessage ?? "An unknown error occurred while fetching billing data."
        ) {
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func warningBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func contentSection<Content: View>(
        title: String,
        systemImage: String,
        message: String,
        @ViewBuilder actions: () -> Content
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            actions()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let nextRefresh = viewModel.nextRefresh {
                    Text("Next refresh \(nextRefresh)")
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
                .disabled(viewModel.isLoading || !viewModel.hasEnabledAccounts)

                Spacer()

                Button {
                    openSettings()
                } label: {
                    Label("Settings", systemImage: "gearshape")
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
