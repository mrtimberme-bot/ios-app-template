import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading = false
    var isDestructive = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(DesignTokens.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(isDestructive ? DesignTokens.Colors.error : DesignTokens.Colors.interactive)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.md) {
        PrimaryButton(title: "Primaire actie") {}
        PrimaryButton(title: "Laden...", action: {}, isLoading: true)
        PrimaryButton(title: "Verwijderen", action: {}, isDestructive: true)
    }
    .padding()
}
