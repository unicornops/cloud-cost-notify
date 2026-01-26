import SwiftUI

struct MenuBarLabelView: View {
    let viewModel: MenuBarViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.menuBarIcon)
                .symbolRenderingMode(.hierarchical)

            Text(viewModel.menuBarText)
                .monospacedDigit()
        }
    }
}
