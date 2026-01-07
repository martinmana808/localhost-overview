import SwiftUI

struct Theme {
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [Color("AccentColor"), Color.blue.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardBackground = Color(NSColor.windowBackgroundColor).opacity(0.6)
    static let glossEffect = Color.white.opacity(0.1)
    
    struct Dimensions {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 12
        static let iconSize: CGFloat = 32
    }
}

extension Color {
    static let textSecondary = Color.secondary
}
