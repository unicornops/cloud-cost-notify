import Foundation

final class AWSCostProvider: CloudCostProvider, @unchecked Sendable {
    let providerType: CloudProviderType = .aws
    private let profileParser: AWSProfileParser
    private let costExplorerClient: AWSCostExplorerClient

    init(profileParser: AWSProfileParser = .shared, costExplorerClient: AWSCostExplorerClient = AWSCostExplorerClient()) {
        self.profileParser = profileParser
        self.costExplorerClient = costExplorerClient
    }

    var isConfigured: Bool {
        profileParser.hasCredentialsFile()
    }

    func discoverAccounts() async throws -> [CloudAccount] {
        let profiles = try profileParser.parseProfiles()
        return profiles.map { profile in
            CloudAccount(
                id: "aws_\(profile.name)",
                provider: .aws,
                name: profile.name,
                profileName: profile.name,
                isEnabled: profile.isEnabled
            )
        }
    }

    func fetchCosts(for accounts: [CloudAccount], period: DateRange) async throws -> CostData {
        let enabledAccounts = accounts.filter { $0.isEnabled && $0.provider == .aws }

        guard !enabledAccounts.isEmpty else {
            throw CloudCostError.noAccountsEnabled
        }

        var allAccountCosts: [AccountCost] = []

        for account in enabledAccounts {
            guard let profileName = account.profileName else { continue }

            do {
                let output = try await costExplorerClient.fetchCosts(
                    profileName: profileName,
                    startDate: period.start,
                    endDate: period.end
                )

                let accountCosts = parseOutput(output, for: account)
                allAccountCosts.append(contentsOf: accountCosts)
            } catch {
                print("Error fetching costs for profile \(profileName): \(error)")
                continue
            }
        }

        let totalCost = allAccountCosts.reduce(Decimal.zero) { $0 + $1.totalCost }

        return CostData(
            provider: .aws,
            period: period,
            totalCost: totalCost,
            currency: "USD",
            accountCosts: allAccountCosts,
            lastUpdated: Date()
        )
    }

    private func parseOutput(_ output: GetCostAndUsageOutput, for account: CloudAccount) -> [AccountCost] {
        let serviceCosts = extractServiceCosts(from: output)

        guard !serviceCosts.isEmpty else {
            return [createEmptyAccountCost(for: account)]
        }

        var accountCosts: [AccountCost] = []

        for (linkedAccountId, services) in serviceCosts {
            if let accountCost = createAccountCost(
                linkedAccountId: linkedAccountId,
                services: services,
                account: account
            ) {
                accountCosts.append(accountCost)
            }
        }

        if accountCosts.isEmpty {
            return [createEmptyAccountCost(for: account)]
        }

        return accountCosts.sorted { $0.totalCost > $1.totalCost }
    }

    private func extractServiceCosts(from output: GetCostAndUsageOutput) -> [String: [String: Decimal]] {
        var serviceCosts: [String: [String: Decimal]] = [:]

        guard let results = output.resultsByTime else { return [:] }

        for result in results {
            guard let groups = result.groups else { continue }

            for group in groups {
                guard let keys = group.keys, keys.count >= 2,
                      let metrics = group.metrics,
                      let unblendedCost = metrics["UnblendedCost"],
                      let amountString = unblendedCost.amount,
                      let amount = Decimal(string: amountString) else { continue }

                let serviceName = keys[0]
                let linkedAccountId = keys[1]

                if serviceCosts[linkedAccountId] == nil {
                    serviceCosts[linkedAccountId] = [:]
                }
                let currentCost = serviceCosts[linkedAccountId]?[serviceName] ?? Decimal.zero
                serviceCosts[linkedAccountId]?[serviceName] = currentCost + amount
            }
        }
        return serviceCosts
    }

    private func createAccountCost(
        linkedAccountId: String,
        services: [String: Decimal],
        account: CloudAccount
    ) -> AccountCost? {
        var resourceCosts: [ResourceCost] = []
        var accountTotal: Decimal = .zero

        for (serviceName, cost) in services.sorted(by: { $0.value > $1.value }) where cost > 0 {
            resourceCosts.append(ResourceCost(
                id: "\(linkedAccountId)_\(serviceName)",
                serviceName: serviceName,
                cost: cost,
                currency: "USD"
            ))
            accountTotal += cost
        }

        guard accountTotal > 0 else { return nil }

        let displayName = linkedAccountId == account.profileName ?
            account.displayName : "\(account.displayName) - \(linkedAccountId)"

        return AccountCost(
            id: "\(account.id)_\(linkedAccountId)",
            accountId: linkedAccountId,
            accountName: displayName,
            totalCost: accountTotal,
            currency: "USD",
            resourceCosts: resourceCosts
        )
    }

    private func createEmptyAccountCost(for account: CloudAccount) -> AccountCost {
        AccountCost(
            id: account.id,
            accountId: account.profileName ?? account.id,
            accountName: account.displayName,
            totalCost: .zero,
            currency: "USD",
            resourceCosts: []
        )
    }
}

import AWSCostExplorer
