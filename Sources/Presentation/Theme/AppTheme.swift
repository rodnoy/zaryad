import Data
import Domain
import SwiftUI
import Foundation

// MARK: - Color extension for hex support

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
            a = 1.0
        case 8:
            r = Double((int >> 24) & 0xFF) / 255.0
            g = Double((int >> 16) & 0xFF) / 255.0
            b = Double((int >> 8) & 0xFF) / 255.0
            a = Double(int & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Card modifier

public struct CardModifier: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    private static let cardCornerRadius: CGFloat = 16
    private static let cardPadding: CGFloat = 20

    public func body(content: Content) -> some View {
        let palette = themeStore.current.palette

        content
            .padding(Self.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Self.cardCornerRadius)
                    .fill(palette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Self.cardCornerRadius)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    )
    }
}

public extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
