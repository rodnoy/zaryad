#!/usr/bin/env swift

import Foundation

struct ThemeExport: Codable {
    struct Palette: Codable {
        let bg: String
        let surface: String
        let surface2: String
        let border: String
        let accent: String
        let accent2: String
        let green: String
        let yellow: String
        let red: String
        let text: String
        let muted: String
    }

    let key: String
    let displayName: [String: String]
    let palette: Palette
}

let builtins: [ThemeExport] = [
    ThemeExport(
        key: "dark",
        displayName: ["en": "Dark", "ru": "Тёмная", "fr": "Sombre"],
        palette: .init(
            bg: "#0a0a0f",
            surface: "#12121a",
            surface2: "#1a1a26",
            border: "#2a2a3d",
            accent: "#00e5ff",
            accent2: "#7c3aed",
            green: "#00ff9d",
            yellow: "#ffd60a",
            red: "#ff3b5c",
            text: "#e8e8f0",
            muted: "#6b6b85"
        )
    ),
    ThemeExport(
        key: "light",
        displayName: ["en": "Light", "ru": "Светлая", "fr": "Clair"],
        palette: .init(
            bg: "#f6f8fc",
            surface: "#ffffff",
            surface2: "#edf1f8",
            border: "#d8e0ef",
            accent: "#0a84ff",
            accent2: "#6e56cf",
            green: "#1fbf75",
            yellow: "#e7a400",
            red: "#e04865",
            text: "#111827",
            muted: "#6b7280"
        )
    ),
    ThemeExport(
        key: "forest",
        displayName: ["en": "Forest", "ru": "Лесная", "fr": "Forêt"],
        palette: .init(
            bg: "#0b1510",
            surface: "#12211a",
            surface2: "#183025",
            border: "#28503e",
            accent: "#4ade80",
            accent2: "#22c55e",
            green: "#34d399",
            yellow: "#eab308",
            red: "#f43f5e",
            text: "#e8f6ec",
            muted: "#8aa39a"
        )
    ),
    ThemeExport(
        key: "marine",
        displayName: ["en": "Marine", "ru": "Морская", "fr": "Marin"],
        palette: .init(
            bg: "#07131f",
            surface: "#0d1f31",
            surface2: "#12304a",
            border: "#1d4a72",
            accent: "#22d3ee",
            accent2: "#3b82f6",
            green: "#2dd4bf",
            yellow: "#facc15",
            red: "#fb7185",
            text: "#e6f1ff",
            muted: "#7da0bf"
        )
    ),
    ThemeExport(
        key: "martian",
        displayName: ["en": "Martian", "ru": "Марсианская", "fr": "Martien"],
        palette: .init(
            bg: "#190b0a",
            surface: "#2a1311",
            surface2: "#3a1b18",
            border: "#6a2f29",
            accent: "#ff6b3d",
            accent2: "#ff8a5b",
            green: "#9be564",
            yellow: "#ffb547",
            red: "#ff4d4d",
            text: "#ffe7df",
            muted: "#c29183"
        )
    ),
]

let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)
let themeSource = root.appendingPathComponent("Sources/Presentation/Theme/Theme.swift")
let resourcesThemes = root.appendingPathComponent("Resources/Themes", isDirectory: true)

let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
let backup = root.appendingPathComponent("Sources/Presentation/Theme/Theme.swift.backup.\(timestamp)")

do {
    if fm.fileExists(atPath: themeSource.path) {
        try fm.copyItem(at: themeSource, to: backup)
        print("Backed up Theme.swift to \(backup.path)")
    }

    if !fm.fileExists(atPath: resourcesThemes.path) {
        try fm.createDirectory(at: resourcesThemes, withIntermediateDirectories: true)
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    for theme in builtins {
        let data = try encoder.encode(theme)
        let fileURL = resourcesThemes.appendingPathComponent("\(theme.key).json")
        try data.write(to: fileURL, options: .atomic)
        print("Wrote \(fileURL.path)")
    }
} catch {
    fputs("theme_export.swift failed: \(error)\n", stderr)
    exit(1)
}
