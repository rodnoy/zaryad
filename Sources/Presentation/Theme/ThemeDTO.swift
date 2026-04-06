import Data
import Domain
import Foundation
import SwiftUI

public struct ThemeDTO: Codable {
    public struct PaletteDTO: Codable {
        public let bg: String
        public let surface: String
        public let surface2: String
        public let border: String
        public let accent: String
        public let accent2: String
        public let green: String
        public let yellow: String
        public let red: String
        public let text: String
        public let muted: String
    }

    public let key: String
    public let displayName: [String: String]
    public let palette: PaletteDTO

    private static let hexRegex = try! NSRegularExpression(pattern: "^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")

    public func validate() -> Bool {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        let colors = [
            palette.bg,
            palette.surface,
            palette.surface2,
            palette.border,
            palette.accent,
            palette.accent2,
            palette.green,
            palette.yellow,
            palette.red,
            palette.text,
            palette.muted,
        ]

        return colors.allSatisfy(Self.isValidHex)
    }

    public static func isValidHex(_ value: String) -> Bool {
        let range = NSRange(location: 0, length: value.utf16.count)
        return hexRegex.firstMatch(in: value, options: [], range: range) != nil
    }

    public func toTheme() -> Theme? {
        guard validate() else {
            return nil
        }

        return Theme(
            key: key,
            displayNameKey: LocalizedStringKey("theme.\(key)"),
            palette: Theme.Palette(
                bg: Color(hex: palette.bg),
                surface: Color(hex: palette.surface),
                surface2: Color(hex: palette.surface2),
                border: Color(hex: palette.border),
                accent: Color(hex: palette.accent),
                accent2: Color(hex: palette.accent2),
                green: Color(hex: palette.green),
                yellow: Color(hex: palette.yellow),
                red: Color(hex: palette.red),
                text: Color(hex: palette.text),
                muted: Color(hex: palette.muted)
            )
        )
    }
}
