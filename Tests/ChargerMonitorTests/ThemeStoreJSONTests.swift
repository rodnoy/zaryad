import Foundation
import XCTest
@testable import Presentation

final class ThemeStoreJSONTests: XCTestCase {
    func testLoadBuiltInThemesLoadsValidJSONAndSkipsInvalid() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory
            .appendingPathComponent("ThemeStoreJSONTests-\(UUID().uuidString)", isDirectory: true)
        let builtInDir = tempRoot.appendingPathComponent("Themes", isDirectory: true)

        try fileManager.createDirectory(at: builtInDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        try validThemeJSON(key: "valid-dark").write(
            to: builtInDir.appendingPathComponent("valid-dark.json"),
            atomically: true,
            encoding: .utf8
        )
        try invalidThemeJSON(key: "invalid-theme").write(
            to: builtInDir.appendingPathComponent("invalid-theme.json"),
            atomically: true,
            encoding: .utf8
        )

        let loader = ThemeLoader(
            fileManager: fileManager,
            bundle: .main,
            builtInThemesDirectoryURL: builtInDir,
            userThemesDirectoryURL: nil
        )

        let loaded = loader.loadBuiltInThemes().map(\.key).sorted()
        XCTAssertEqual(loaded, ["valid-dark"])
    }

    private func validThemeJSON(key: String) -> String {
        """
        {
          "key": "\(key)",
          "displayName": {
            "en": "Valid",
            "ru": "Корректная",
            "fr": "Valide"
          },
          "palette": {
            "bg": "#0a0a0f",
            "surface": "#12121a",
            "surface2": "#1a1a26",
            "border": "#2a2a3d",
            "accent": "#00e5ff",
            "accent2": "#7c3aed",
            "green": "#00ff9d",
            "yellow": "#ffd60a",
            "red": "#ff3b5c",
            "text": "#e8e8f0",
            "muted": "#6b6b85"
          }
        }
        """
    }

    private func invalidThemeJSON(key: String) -> String {
        """
        {
          "key": "\(key)",
          "displayName": {
            "en": "Invalid"
          },
          "palette": {
            "bg": "not-a-hex",
            "surface": "#12121a",
            "surface2": "#1a1a26",
            "border": "#2a2a3d",
            "accent": "#00e5ff",
            "accent2": "#7c3aed",
            "green": "#00ff9d",
            "yellow": "#ffd60a",
            "red": "#ff3b5c",
            "text": "#e8e8f0",
            "muted": "#6b6b85"
          }
        }
        """
    }
}
