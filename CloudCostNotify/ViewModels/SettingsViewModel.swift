import Foundation
import SwiftUI
import ServiceManagement

@MainActor
@Observable
final class SettingsViewModel {
    private let costService: CostAggregationService

    var availableProfiles: [AWSProfile] {
        costService.availableProfiles
    }

    var selectedRefreshInterval: RefreshScheduler.RefreshInterval {
        costService.refreshScheduler.interval
    }

    var launchAtLogin: Bool = false

    init(costService: CostAggregationService) {
        self.costService = costService
        loadLaunchAtLoginState()
    }

    func toggleProfile(_ profileName: String, enabled: Bool) async {
        await costService.setProfileEnabled(profileName, enabled: enabled)
    }

    func setRefreshInterval(_ interval: RefreshScheduler.RefreshInterval) async {
        await costService.setRefreshInterval(interval)
    }

    func refreshProfiles() async {
        await costService.loadProfiles()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
            launchAtLogin = !enabled
        }
    }

    private func loadLaunchAtLoginState() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    var enabledProfileCount: Int {
        availableProfiles.filter { $0.isEnabled }.count
    }

    var isConfigured: Bool {
        costService.isConfigured
    }

    func clearCache() async {
        await costService.clearCache()
    }
}
