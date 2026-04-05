import Data
import Domain
import SwiftUI

public struct Theme {
    public struct Palette {
        public let bg: Color
        public let surface: Color
        public let surface2: Color
        public let border: Color
        public let accent: Color
        public let accent2: Color
        public let green: Color
        public let yellow: Color
        public let red: Color
        public let text: Color
        public let muted: Color

        public init(
            bg: Color,
            surface: Color,
            surface2: Color,
            border: Color,
            accent: Color,
            accent2: Color,
            green: Color,
            yellow: Color,
            red: Color,
            text: Color,
            muted: Color
        ) {
            self.bg = bg
            self.surface = surface
            self.surface2 = surface2
            self.border = border
            self.accent = accent
            self.accent2 = accent2
            self.green = green
            self.yellow = yellow
            self.red = red
            self.text = text
            self.muted = muted
        }
    }

    public let key: String
    public let displayNameKey: LocalizedStringKey
    public let palette: Palette

    public init(key: String, displayNameKey: LocalizedStringKey, palette: Palette) {
        self.key = key
        self.displayNameKey = displayNameKey
        self.palette = palette
    }

    public init(key: String) {
        self = Theme.forKey(key)
    }

    public static let dark = Theme(
        key: "dark",
        displayNameKey: "theme.dark",
        palette: Palette(
            bg: Color(hex: "0a0a0f"),
            surface: Color(hex: "12121a"),
            surface2: Color(hex: "1a1a26"),
            border: Color(hex: "2a2a3d"),
            accent: Color(hex: "00e5ff"),
            accent2: Color(hex: "7c3aed"),
            green: Color(hex: "00ff9d"),
            yellow: Color(hex: "ffd60a"),
            red: Color(hex: "ff3b5c"),
            text: Color(hex: "e8e8f0"),
            muted: Color(hex: "6b6b85")
        )
    )

    public static let light = Theme(
        key: "light",
        displayNameKey: "theme.light",
        palette: Palette(
            bg: Color(hex: "f6f8fc"),
            surface: Color(hex: "ffffff"),
            surface2: Color(hex: "edf1f8"),
            border: Color(hex: "d8e0ef"),
            accent: Color(hex: "0a84ff"),
            accent2: Color(hex: "6e56cf"),
            green: Color(hex: "1fbf75"),
            yellow: Color(hex: "e7a400"),
            red: Color(hex: "e04865"),
            text: Color(hex: "111827"),
            muted: Color(hex: "6b7280")
        )
    )

    public static let forest = Theme(
        key: "forest",
        displayNameKey: "theme.forest",
        palette: Palette(
            bg: Color(hex: "0b1510"),
            surface: Color(hex: "12211a"),
            surface2: Color(hex: "183025"),
            border: Color(hex: "28503e"),
            accent: Color(hex: "4ade80"),
            accent2: Color(hex: "22c55e"),
            green: Color(hex: "34d399"),
            yellow: Color(hex: "eab308"),
            red: Color(hex: "f43f5e"),
            text: Color(hex: "e8f6ec"),
            muted: Color(hex: "8aa39a")
        )
    )

    public static let marine = Theme(
        key: "marine",
        displayNameKey: "theme.marine",
        palette: Palette(
            bg: Color(hex: "07131f"),
            surface: Color(hex: "0d1f31"),
            surface2: Color(hex: "12304a"),
            border: Color(hex: "1d4a72"),
            accent: Color(hex: "22d3ee"),
            accent2: Color(hex: "3b82f6"),
            green: Color(hex: "2dd4bf"),
            yellow: Color(hex: "facc15"),
            red: Color(hex: "fb7185"),
            text: Color(hex: "e6f1ff"),
            muted: Color(hex: "7da0bf")
        )
    )

    public static let martian = Theme(
        key: "martian",
        displayNameKey: "theme.martian",
        palette: Palette(
            bg: Color(hex: "190b0a"),
            surface: Color(hex: "2a1311"),
            surface2: Color(hex: "3a1b18"),
            border: Color(hex: "6a2f29"),
            accent: Color(hex: "ff6b3d"),
            accent2: Color(hex: "ff8a5b"),
            green: Color(hex: "9be564"),
            yellow: Color(hex: "ffb547"),
            red: Color(hex: "ff4d4d"),
            text: Color(hex: "ffe7df"),
            muted: Color(hex: "c29183")
        )
    )

    public static func forKey(_ key: String) -> Theme {
        switch key {
        case light.key: return light
        case forest.key: return forest
        case marine.key: return marine
        case martian.key: return martian
        default: return dark
        }
    }
}
