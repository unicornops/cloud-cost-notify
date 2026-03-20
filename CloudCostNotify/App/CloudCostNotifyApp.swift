import SwiftUI

@main
struct CloudCostNotifyApp: App {
    private let costService: CostAggregationService
    private let menuBarViewModel: MenuBarViewModel
    private let settingsViewModel: SettingsViewModel

    init() {
        let costService = CostAggregationService()
        self.costService = costService
        self.menuBarViewModel = MenuBarViewModel(costService: costService)
        self.settingsViewModel = SettingsViewModel(costService: costService)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: menuBarViewModel)
        } label: {
            MenuBarLabelView(viewModel: menuBarViewModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: settingsViewModel)
        }
    }
}
