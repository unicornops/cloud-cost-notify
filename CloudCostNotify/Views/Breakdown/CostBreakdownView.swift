import SwiftUI

struct CostBreakdownView: View {
    let costData: [CostData]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(costData, id: \.provider) { data in
                    ProviderRowView(costData: data)
                }
            }
        }
        .frame(maxHeight: 300)
    }
}
