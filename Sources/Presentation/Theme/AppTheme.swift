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

// MARK: - App Theme Colors (matching web CSS)

public enum AppTheme {
    // Read current palette from UserDefaults synchronously so AppTheme can be
    // accessed from nonisolated contexts (e.g. default parameter values).
    private static var palette: Theme.Palette {
        let key = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.dark.key
        return Theme.forKey(key).palette
    }

    // Backgrounds
    public static var bg: Color { palette.bg }
    public static var surface: Color { palette.surface }
    public static var surface2: Color { palette.surface2 }
    public static var border: Color { palette.border }

    // Accents
    public static var accent: Color { palette.accent }
    public static var accent2: Color { palette.accent2 }
    public static var green: Color { palette.green }
    public static var yellow: Color { palette.yellow }
    public static var red: Color { palette.red }

    // Text
    public static var text: Color { palette.text }
    public static var muted: Color { palette.muted }
    /// Slightly dimmer header/label color used for card section titles.
    public static var header: Color { palette.muted.opacity(0.88) }

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
                    )
    }
}

public extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
