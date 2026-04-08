import XCTest
@testable import Presentation

final class ThemeLoaderHotReloadTests: XCTestCase {
    func testLoadUserThemesReflectsFileSystemChanges() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory
            .appendingPathComponent("ThemeLoaderHotReloadTests-\(UUID().uuidString)", isDirectory: true)
        let themesDir = tempRoot.appendingPathComponent("themes", isDirectory: true)

        try fileManager.createDirectory(at: themesDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let loader = ThemeLoader(
            fileManager: fileManager,
            bundle: .main,
            userThemesDirectoryURL: themesDir
        )

        XCTAssertTrue(loader.loadUserThemes().isEmpty)

        let themeURL = themesDir.appendingPathComponent("temp.json")
        try validThemeJSON(key: "temp-theme").write(to: themeURL, atomically: true, encoding: .utf8)

        let loadedAfterAdd = loader.loadUserThemes()
        XCTAssertEqual(loadedAfterAdd.map(\.key), ["temp-theme"])

        try fileManager.removeItem(at: themeURL)

        let loadedAfterRemove = loader.loadUserThemes()
        XCTAssertTrue(loadedAfterRemove.isEmpty)
    }

    private func validThemeJSON(key: String) -> String {
        """
        {
          "key": "\(key)",
          "displayName": {
            "en": "Temp",
            "ru": "Временная",
            "fr": "Temporaire"
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
}
