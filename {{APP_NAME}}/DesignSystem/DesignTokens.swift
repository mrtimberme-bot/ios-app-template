import SwiftUI

enum DesignTokens {

    enum Colors {
        static let brand = Color("Brand")
        static let background = Color("Background")
        static let backgroundSecondary = Color("BackgroundSecondary")
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let interactive = Color("Interactive")
        static let interactivePressed = Color("InteractivePressed")
        static let success = Color("Success")
        static let warning = Color("Warning")
        static let error = Color("Error")
        static let separator = Color("Separator")
    }

    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title2.weight(.semibold)
        static let headline = Font.headline
        static let body = Font.body
        static let caption = Font.caption
        static let footnote = Font.footnote
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
}
