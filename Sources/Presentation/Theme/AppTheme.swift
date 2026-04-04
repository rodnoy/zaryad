import SwiftUI

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

// MARK: - App Theme Colors (matching web CSS)

public enum AppTheme {
    // Backgrounds
    public static let bg       = Color(hex: "0a0a0f")
    public static let surface  = Color(hex: "12121a")
    public static let surface2 = Color(hex: "1a1a26")
    public static let border   = Color(hex: "2a2a3d")

    // Accents
    public static let accent   = Color(hex: "00e5ff")
    public static let accent2  = Color(hex: "7c3aed")
    public static let green    = Color(hex: "00ff9d")
    public static let yellow   = Color(hex: "ffd60a")
    public static let red      = Color(hex: "ff3b5c")

    // Text
    public static let text     = Color(hex: "e8e8f0")
    public static let muted    = Color(hex: "6b6b85")

    // Card
    public static let cardCornerRadius: CGFloat = 16
    public static let cardPadding: CGFloat = 20

    // Fonts
    public static let monoFont: Font = .system(.body, design: .monospaced)
    public static func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // Gradient for battery bar
    public static func batteryGradient(percent: Double) -> LinearGradient {
        if percent <= 20 {
            return LinearGradient(colors: [red, Color(hex: "ff6b35")], startPoint: .leading, endPoint: .trailing)
        } else if percent <= 40 {
            return LinearGradient(colors: [yellow, Color(hex: "ff9500")], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [green, accent], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Card modifier

public struct CardModifier: ViewModifier {
    var topAccentColor: Color?

    public func body(content: Content) -> some View {
        content
            .padding(AppTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .overlay(alignment: .top) {
                        if let color = topAccentColor {
                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                .fill(color)
                                .frame(height: 2)
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: AppTheme.cardCornerRadius,
                                        bottomLeadingRadius: 0,
                                        bottomTrailingRadius: 0,
                                        topTrailingRadius: AppTheme.cardCornerRadius
                                    )
                                )
                        }
                    }
            )
    }
}

public extension View {
    func cardStyle(topAccent: Color? = nil) -> some View {
        modifier(CardModifier(topAccentColor: topAccent))
    }
}
