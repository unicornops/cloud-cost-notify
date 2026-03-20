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
    private(set) var awsSharedConfigDirectoryURL: URL?

    private let awsProvider: AWSCostProvider
    private let cacheService: CacheService
    let refreshScheduler: RefreshScheduler

    var totalCost: Decimal {
        costData.reduce(.zero) { $0 + $1.totalCost }
    }

    var formattedTotalCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalCost as NSDecimalNumber) ?? "$0.00"
    }

    var lastUpdated: Date? {
        costData.map(\.lastUpdated).max()
    }

    var formattedLastUpdated: String? {
        guard let date = lastUpdated else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var supportedProviders: [CloudProviderType] {
        CloudProviderType.allCases
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
        await loadProviderConfiguration()
        await loadProfiles()
        refreshScheduler.start()
    }

    func loadProfiles() async {
        await awsProvider.updateSharedConfigDirectory(awsSharedConfigDirectoryURL)

        do {
            let enabledProfileNames = await cacheService.loadEnabledProfiles()
            let profiles = try AWSProfileParser.shared.parseProfiles(in: awsSharedConfigDirectoryURL)

            availableProfiles = profiles.map { profile in
                var mutableProfile = profile
                mutableProfile.isEnabled = enabledProfileNames.contains(profile.name)
                return mutableProfile
            }

            let discoveredAccounts = try await awsProvider.discoverAccounts()
            accounts = discoveredAccounts.map { account in
                var mutableAccount = account
                if let profileName = account.profileName {
                    mutableAccount.isEnabled = enabledProfileNames.contains(profileName)
                }
                return mutableAccount
            }
        } catch let error as CloudCostError {
            availableProfiles = []
            accounts = []
            if awsSharedConfigDirectoryURL != nil {
                lastError = error
            }
        } catch {
            availableProfiles = []
            accounts = []
            lastError = .parseError(error.localizedDescription)
        }
    }

    func setProfileEnabled(_ profileName: String, enabled: Bool) async {
        if let index = availableProfiles.firstIndex(where: { $0.name == profileName }) {
            availableProfiles[index].isEnabled = enabled
        }

        for index in accounts.indices where accounts[index].profileName == profileName {
            accounts[index].isEnabled = enabled
        }

        let enabledProfiles = Set(availableProfiles.filter { $0.isEnabled }.map(\.name))
        await cacheService.saveEnabledProfiles(enabledProfiles)
    }

    func setAWSSharedConfigDirectory(_ directoryURL: URL) async throws {
        let bookmark = try directoryURL.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        await cacheService.saveAWSSharedConfigDirectoryBookmark(bookmark)
        awsSharedConfigDirectoryURL = directoryURL
        lastError = nil
        await loadProfiles()
    }

    func clearAWSSharedConfigDirectory() async {
        await cacheService.saveAWSSharedConfigDirectoryBookmark(nil)
        awsSharedConfigDirectoryURL = nil
        availableProfiles = []
        accounts = []
        costData.removeAll { $0.provider == .aws }
        await awsProvider.updateSharedConfigDirectory(nil)
    }

    func fetchCosts() async {
        let enabledAccounts = accounts.filter { $0.isEnabled }
        guard !enabledAccounts.isEmpty else {
            loadingState = .error("Enable at least one AWS profile in Settings.")
            return
        }

        loadingState = .loading
        lastError = nil

        do {
            var fetchedCostData: [CostData] = []
            let period = DateRange.monthToDate

            if enabledAccounts.contains(where: { $0.provider == .aws }) {
                let awsCostData = try await awsProvider.fetchCosts(for: enabledAccounts, period: period)
                fetchedCostData.append(awsCostData)
            }

            costData = fetchedCostData.sorted { $0.provider.rawValue < $1.provider.rawValue }
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

    func setRefreshInterval(_ interval: RefreshScheduler.RefreshInterval) async {
        refreshScheduler.setInterval(interval)
        await cacheService.saveRefreshInterval(interval.rawValue)
    }

    func clearCache() async {
        await cacheService.clearCache()
        costData = []
        if hasEnabledAccounts {
            loadingState = .loaded
        } else {
            loadingState = .idle
        }
    }

    var hasEnabledAccounts: Bool {
        accounts.contains { $0.isEnabled }
    }

    var isConfigured: Bool {
        awsProvider.isConfigured
    }

    var awsSharedConfigDirectoryName: String? {
        awsSharedConfigDirectoryURL?.lastPathComponent
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

    private func loadProviderConfiguration() async {
        guard let bookmark = await cacheService.loadAWSSharedConfigDirectoryBookmark() else {
            await awsProvider.updateSharedConfigDirectory(nil)
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                let refreshedBookmark = try url.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                await cacheService.saveAWSSharedConfigDirectoryBookmark(refreshedBookmark)
            }

            awsSharedConfigDirectoryURL = url
            await awsProvider.updateSharedConfigDirectory(url)
        } catch {
            awsSharedConfigDirectoryURL = nil
            await cacheService.saveAWSSharedConfigDirectoryBookmark(nil)
            await awsProvider.updateSharedConfigDirectory(nil)
        }
    }
}
