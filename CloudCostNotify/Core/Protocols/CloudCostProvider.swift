import Foundation

protocol CloudCostProvider: Sendable {
    var providerType: CloudProviderType { get }
    var isConfigured: Bool { get }

    func fetchCosts(for accounts: [CloudAccount], period: DateRange) async throws -> CostData
    func discoverAccounts() async throws -> [CloudAccount]
}
