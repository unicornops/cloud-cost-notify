import SwiftUI

@main
struct CloudCostNotifyApp: App {
    @State private var costService = CostAggregationService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: MenuBarViewModel(costService: costService))
        } label: {
            MenuBarLabelView(viewModel: MenuBarViewModel(costService: costService))
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: SettingsViewModel(costService: costService))
        }
    }
}
