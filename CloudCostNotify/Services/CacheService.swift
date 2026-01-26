import Foundation

actor CacheService {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum CacheKey: String {
        case costData = "cached_cost_data"
        case lastFetchDate = "last_fetch_date"
        case enabledProfiles = "enabled_profiles"
        case refreshInterval = "refresh_interval"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func cacheCostData(_ costData: [CostData]) throws {
        let data = try encoder.encode(costData)
        userDefaults.set(data, forKey: CacheKey.costData.rawValue)
        userDefaults.set(Date(), forKey: CacheKey.lastFetchDate.rawValue)
    }

    func loadCachedCostData() throws -> [CostData]? {
        guard let data = userDefaults.data(forKey: CacheKey.costData.rawValue) else {
            return nil
        }
        return try decoder.decode([CostData].self, from: data)
    }

    func lastFetchDate() -> Date? {
        userDefaults.object(forKey: CacheKey.lastFetchDate.rawValue) as? Date
    }

    func saveEnabledProfiles(_ profiles: Set<String>) {
        userDefaults.set(Array(profiles), forKey: CacheKey.enabledProfiles.rawValue)
    }

    func loadEnabledProfiles() -> Set<String> {
        guard let array = userDefaults.stringArray(forKey: CacheKey.enabledProfiles.rawValue) else {
            return []
        }
        return Set(array)
    }

    func saveRefreshInterval(_ minutes: Int) {
        userDefaults.set(minutes, forKey: CacheKey.refreshInterval.rawValue)
    }

    func loadRefreshInterval() -> Int {
        let value = userDefaults.integer(forKey: CacheKey.refreshInterval.rawValue)
        return value > 0 ? value : 60
    }

    func clearCache() {
        userDefaults.removeObject(forKey: CacheKey.costData.rawValue)
        userDefaults.removeObject(forKey: CacheKey.lastFetchDate.rawValue)
    }

    func isCacheValid(maxAge: TimeInterval) -> Bool {
        guard let lastFetch = lastFetchDate() else {
            return false
        }
        return Date().timeIntervalSince(lastFetch) < maxAge
    }
}
