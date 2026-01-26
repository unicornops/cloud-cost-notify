import SwiftUI

struct AccountRowView: View {
    let accountCost: AccountCost
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(accountCost.resourceCosts) { resourceCost in
                ResourceRowView(resourceCost: resourceCost)
                    .padding(.leading, 8)
            }
        } label: {
            HStack {
                Image(systemName: "person.circle")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(accountCost.accountName)
                        .lineLimit(1)

                    Text(accountCost.accountId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(accountCost.formattedTotalCost)
                    .monospacedDigit()
            }
        }
    }
}
