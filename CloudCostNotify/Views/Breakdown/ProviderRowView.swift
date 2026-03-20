import SwiftUI

struct ProviderRowView: View {
    let costData: CostData
    let selectedTab: CostBreakdownView.BreakdownTab
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                switch selectedTab {
                case .scopes:
                    ForEach(costData.accountCosts) { accountCost in
                        AccountRowView(accountCost: accountCost, provider: costData.provider)
                    }
                case .resources:
                    ForEach(costData.aggregatedResourceCosts) { resourceCost in
                        ResourceRowView(resourceCost: resourceCost)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Label(costData.provider.rawValue, systemImage: costData.provider.iconName)
                        .font(.headline)

                    Spacer()

                    Text(costData.formattedTotalCost)
                        .font(.headline)
                        .monospacedDigit()
                }

                Text(sectionSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var sectionSubtitle: String {
        switch selectedTab {
        case .scopes:
            return "\(costData.accountCosts.count) \(costData.provider.scopePluralTitle.lowercased())"
        case .resources:
            return "\(costData.aggregatedResourceCosts.count) resource types"
        }
    }
}
