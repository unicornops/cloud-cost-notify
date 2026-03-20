import SwiftUI

struct CostBreakdownView: View {
    enum BreakdownTab: String, CaseIterable, Identifiable {
        case scopes
        case resources

        var id: String { rawValue }

        var title: String {
            switch self {
            case .scopes:
                return "By Account"
            case .resources:
                return "By Resource"
            }
        }
    }

    let costData: [CostData]
    @State private var selectedTab: BreakdownTab = .scopes

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Breakdown", selection: $selectedTab) {
                ForEach(BreakdownTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if costData.isEmpty {
                        ContentUnavailableView(
                            "No Cost Data Yet",
                            systemImage: "chart.bar.xaxis",
                            description: Text("Refresh after enabling at least one cloud account.")
                        )
                    } else {
                        ForEach(costData, id: \.provider) { data in
                            ProviderRowView(costData: data, selectedTab: selectedTab)
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
        }
    }
}
