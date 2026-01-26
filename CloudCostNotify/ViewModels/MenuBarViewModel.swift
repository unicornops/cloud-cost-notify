import Foundation
import SwiftUI

@MainActor
@Observable
final class MenuBarViewModel {
    private let costService: CostAggregationService

    init(costService: CostAggregationService) {
        self.costService = costService
    }

    var displayCost: String {
        costService.formattedTotalCost
    }

    var isLoading: Bool {
        costService.loadingState == .loading
    }

    var hasError: Bool {
        if case .error = costService.loadingState {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = costService.loadingState {
            return message
        }
        return nil
    }

    var lastUpdated: String? {
        costService.formattedLastUpdated
    }

    var costData: [CostData] {
        costService.costData
    }

    var statusText: String {
        switch costService.loadingState {
        case .idle:
            return "Not configured"
        case .loading:
            return "Updating..."
        case .loaded:
            if let updated = lastUpdated {
                return "Updated \(updated)"
            }
            return "Up to date"
        case .error(let message):
            return message
        }
    }

    var menuBarText: String {
        if isLoading {
            return "..."
        }
        return displayCost
    }

    var menuBarIcon: String {
        if hasError {
            return "exclamationmark.triangle"
        }
        return "dollarsign.circle"
    }

    func refresh() async {
        await costService.fetchCosts()
    }

    func initialize() async {
        await costService.initialize()
    }

    var isConfigured: Bool {
        costService.isConfigured
    }

    var hasEnabledAccounts: Bool {
        costService.hasEnabledAccounts
    }

    var nextRefresh: String? {
        costService.refreshScheduler.formattedTimeUntilNextRefresh
    }
}
