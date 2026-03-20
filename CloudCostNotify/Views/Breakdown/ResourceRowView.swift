import SwiftUI

struct ResourceRowView: View {
    let resourceCost: ResourceCost

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "shippingbox")
                .foregroundStyle(.secondary)
                .font(.caption)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(resourceCost.serviceName)
                    .font(.callout)
                    .lineLimit(1)

                if let usage = resourceCost.formattedUsage {
                    Text(usage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(resourceCost.formattedCost)
                .font(.callout)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .padding(.leading, 28)
    }
}
