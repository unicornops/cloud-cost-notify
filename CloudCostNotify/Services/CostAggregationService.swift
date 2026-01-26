import Foundation
import SwiftUI

@MainActor
@Observable
final class CostAggregationService {
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var costData: [CostData] = []
    private(set) var loadingState: LoadingState = .idle
    private(set) var lastError: CloudCostError?
    private(set) var accounts: [CloudAccount] = []
    private(set) var availableProfiles: [AWSProfile] = []

    private let awsProvider: AWSCostProvider
    private let cacheService: CacheService
    let refreshScheduler: RefreshScheduler

    var totalCost: Decimal {
        costData.reduce(Decimal.zero) { $0 + $1.totalCost }
    }

    var formattedTotalCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalCost as NSDecimalNumber) ?? "$0.00"
    }

    var lastUpdated: Date? {
        costData.first?.lastUpdated
    }

    var formattedLastUpdated: String? {
        guard let date = lastUpdated else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    init() {
        self.awsProvider = AWSCostProvider()
        self.cacheService = CacheService()
        self.refreshScheduler = RefreshScheduler()

        refreshScheduler.setRefreshAction { [weak self] in
            await self?.fetchCosts()
        }
    }

    func initialize() async {
        await loadCachedData()
        await loadProfiles()
        refreshScheduler.start()
    }

    func loadProfiles() async {
        do {
            availableProfiles = try AWSProfileParser.shared.parseProfiles()
            let enabledProfileNames = await cacheService.loadEnabledProfiles()

            availableProfiles = availableProfiles.map { profile in
                var mutableProfile = profile
                mutableProfile.isEnabled = enabledProfileNames.contains(profile.name)
                return mutableProfile
            }

            accounts = try await awsProvider.discoverAccounts()
            accounts = accounts.map { account in
                var mutableAccount = account
                if let profileName = account.profileName {
                    mutableAccount.isEnabled = enabledProfileNames.contains(profileName)
                }
                return mutableAccount
            }
        } catch {
            print("Error loading profiles: \(error)")
        }
    }

    func setProfileEnabled(_ profileName: String, enabled: Bool) async {
        if let index = availableProfiles.firstIndex(where: { $0.name == profileName }) {
            availableProfiles[index].isEnabled = enabled
        }

        if let index = accounts.firstIndex(where: { $0.profileName == profileName }) {
            accounts[index].isEnabled = enabled
        }

        let enabledProfiles = Set(availableProfiles.filter { $0.isEnabled }.map { $0.name })
        await cacheService.saveEnabledProfiles(enabledProfiles)
    }

    func fetchCosts() async {
        guard !accounts.filter({ $0.isEnabled }).isEmpty else {
            loadingState = .error("No accounts enabled")
            return
        }

        loadingState = .loading
        lastError = nil

        do {
            let period = DateRange.monthToDate
            let data = try await awsProvider.fetchCosts(for: accounts, period: period)
            costData = [data]
            loadingState = .loaded

            try await cacheService.cacheCostData(costData)
        } catch let error as CloudCostError {
            lastError = error
            loadingState = .error(error.localizedDescription)
        } catch {
            lastError = .networkError(error)
            loadingState = .error(error.localizedDescription)
        }
    }

    private func loadCachedData() async {
        do {
            if let cached = try await cacheService.loadCachedCostData() {
                costData = cached
                loadingState = .loaded
            }
        } catch {
            print("Error loading cached data: \(error)")
        }

        let interval = await cacheService.loadRefreshInterval()
        if let refreshInterval = RefreshScheduler.RefreshInterval(rawValue: interval) {
            refreshScheduler.setInterval(refreshInterval)
        }
    }

    func setRefreshInterval(_ interval: RefreshScheduler.RefreshInterval) async {
        refreshScheduler.setInterval(interval)
        await cacheService.saveRefreshInterval(interval.rawValue)
    }

    func clearCache() async {
        await cacheService.clearCache()
        costData = []
        loadingState = .idle
    }

    var hasEnabledAccounts: Bool {
        accounts.contains { $0.isEnabled }
    }

    var isConfigured: Bool {
        awsProvider.isConfigured
    }
}
