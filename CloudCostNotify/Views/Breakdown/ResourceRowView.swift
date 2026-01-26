import SwiftUI

struct ResourceRowView: View {
    let resourceCost: ResourceCost

    var body: some View {
        HStack {
            Image(systemName: "cube")
                .foregroundStyle(.secondary)
                .font(.caption)

            Text(resourceCost.serviceName)
                .font(.callout)
                .lineLimit(1)

            Spacer()

            Text(resourceCost.formattedCost)
                .font(.callout)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}
