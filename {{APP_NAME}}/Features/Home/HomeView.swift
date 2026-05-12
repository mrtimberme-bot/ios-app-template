import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Welkom bij {{APP_NAME}}")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
            .padding(DesignTokens.Spacing.md)
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
