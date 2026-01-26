import SwiftUI

struct ProviderRowView: View {
    let costData: CostData
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(costData.accountCosts) { accountCost in
                AccountRowView(accountCost: accountCost)
                    .padding(.leading, 8)
            }
        } label: {
            HStack {
                Image(systemName: costData.provider.iconName)
                    .foregroundStyle(.blue)

                Text(costData.provider.rawValue)
                    .fontWeight(.medium)

                Spacer()

                Text(costData.formattedTotalCost)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        }
    }
}
