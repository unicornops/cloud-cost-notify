import SwiftUI

struct AccountRowView: View {
    let accountCost: AccountCost
    let provider: CloudProviderType
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                if accountCost.resourceCosts.isEmpty {
                    Text("No resource-level costs reported for this \(provider.scopeSingularTitle.lowercased()).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 28)
                } else {
                    ForEach(accountCost.resourceCosts) { resourceCost in
                        ResourceRowView(resourceCost: resourceCost)
                    }
                }
            }
            .padding(.top, 6)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(.secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(accountCost.accountName)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text("\(provider.scopeSingularTitle): \(accountCost.accountId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(accountCost.formattedTotalCost)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
        }
    }
}
