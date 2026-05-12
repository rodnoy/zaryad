import Foundation
import XCTest
@testable import Presentation

@MainActor
final class ThemeImportTests: XCTestCase {
    private var tempRoot: URL!
    private var builtInDir: URL!
    private var userDir: URL!
    private let fileManager = FileManager.default

    override func setUp() {
        super.setUp()
        tempRoot = fileManager.temporaryDirectory
            .appendingPathComponent("ThemeImportTests-\(UUID().uuidString)", isDirectory: true)
        builtInDir = tempRoot.appendingPathComponent("BuiltIn", isDirectory: true)
        userDir = tempRoot.appendingPathComponent("User", isDirectory: true)
        try? fileManager.createDirectory(at: builtInDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: userDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? fileManager.removeItem(at: tempRoot)
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeThemeStore() -> ThemeStore {
        let loader = ThemeLoader(
            fileManager: fileManager,
            bundle: .main,
            builtInThemesDirectoryURL: builtInDir,
            userThemesDirectoryURL: userDir
        )
        return ThemeStore(
            userDefaults: UserDefaults(suiteName: "ThemeImportTests-\(UUID().uuidString)")!,
            loader: loader,
            fileManager: fileManager
        )
    }

    private func writeFile(content: String, name: String, in directory: URL) -> URL {
        let url = directory.appendingPathComponent(name)
        try! content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func validThemeJSON(key: String) -> String {
        """
        {
          "key": "\(key)",
          "displayName": {
            "en": "Test \(key)",
            "ru": "Тест \(key)",
            "fr": "Test \(key)"
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

    private func invalidThemeJSON() -> String {
        """
        {
          "key": "bad-theme",
          "displayName": { "en": "Bad" },
          "palette": {
            "bg": "not-hex",
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

    // MARK: - Tests

    func testImportValidThemeCopiesFileAndAppearsInAllThemes() throws {
        let store = makeThemeStore()
        let sourceFile = writeFile(
            content: validThemeJSON(key: "imported-neon"),
            name: "imported-neon.json",
            in: tempRoot
        )

        let theme = try store.importTheme(from: sourceFile)

        XCTAssertEqual(theme.key, "imported-neon")
        XCTAssertTrue(store.allThemes.contains(where: { $0.key == "imported-neon" }))
        XCTAssertEqual(store.currentKey, "imported-neon")

        // File should exist in user themes dir
        let destFile = userDir.appendingPathComponent("imported-neon.json")
        XCTAssertTrue(fileManager.fileExists(atPath: destFile.path))
    }

    func testImportInvalidJSONIsRejected() {
        let store = makeThemeStore()
        let sourceFile = writeFile(
            content: "{ this is not valid json",
            name: "garbage.json",
            in: tempRoot
        )

        XCTAssertThrowsError(try store.importTheme(from: sourceFile)) { error in
            guard let importError = error as? ThemeStore.ImportError else {
                XCTFail("Expected ThemeStore.ImportError, got \(type(of: error))")
                return
            }
            if case .invalidTheme = importError {} else {
                XCTFail("Expected .invalidTheme, got \(importError)")
            }
        }
    }

    func testImportInvalidPaletteIsRejected() {
        let store = makeThemeStore()
        let sourceFile = writeFile(
            content: invalidThemeJSON(),
            name: "bad-theme.json",
            in: tempRoot
        )

        XCTAssertThrowsError(try store.importTheme(from: sourceFile)) { error in
            guard let importError = error as? ThemeStore.ImportError else {
                XCTFail("Expected ThemeStore.ImportError, got \(type(of: error))")
                return
            }
            if case .invalidTheme = importError {} else {
                XCTFail("Expected .invalidTheme, got \(importError)")
            }
        }

        // File should NOT appear in user themes dir
        let destFile = userDir.appendingPathComponent("bad-theme.json")
        XCTAssertFalse(fileManager.fileExists(atPath: destFile.path))
    }

    func testImportDuplicateKeyIsRejectedNoOverwrite() throws {
        let store = makeThemeStore()

        // First import succeeds
        let sourceFile1 = writeFile(
            content: validThemeJSON(key: "duplicate-test"),
            name: "duplicate-test-1.json",
            in: tempRoot
        )
        try store.importTheme(from: sourceFile1)

        // Second import with same key should fail
        let sourceFile2 = writeFile(
            content: validThemeJSON(key: "duplicate-test"),
            name: "duplicate-test-2.json",
            in: tempRoot
        )

        XCTAssertThrowsError(try store.importTheme(from: sourceFile2)) { error in
            guard let importError = error as? ThemeStore.ImportError else {
                XCTFail("Expected ThemeStore.ImportError, got \(type(of: error))")
                return
            }
            if case .alreadyExists(let key) = importError {
                XCTAssertEqual(key, "duplicate-test")
            } else {
                XCTFail("Expected .alreadyExists, got \(importError)")
            }
        }
    }

    func testImportNonexistentFileThrowsReadError() {
        let store = makeThemeStore()
        let fakeURL = tempRoot.appendingPathComponent("does-not-exist.json")

        XCTAssertThrowsError(try store.importTheme(from: fakeURL)) { error in
            guard let importError = error as? ThemeStore.ImportError else {
                XCTFail("Expected ThemeStore.ImportError, got \(type(of: error))")
                return
            }
            if case .readFailed = importError {} else {
                XCTFail("Expected .readFailed, got \(importError)")
            }
        }
    }

    func testImportMissingRequiredFieldsFailsValidation() {
        let store = makeThemeStore()
        // JSON missing "muted" field entirely
        let json = """
        {
          "key": "incomplete",
          "displayName": { "en": "Incomplete" },
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
            "text": "#e8e8f0"
          }
        }
        """
        let sourceFile = writeFile(content: json, name: "incomplete.json", in: tempRoot)

        XCTAssertThrowsError(try store.importTheme(from: sourceFile)) { error in
            guard let importError = error as? ThemeStore.ImportError else {
                XCTFail("Expected ThemeStore.ImportError, got \(type(of: error))")
                return
            }
            if case .invalidTheme = importError {} else {
                XCTFail("Expected .invalidTheme, got \(importError)")
            }
        }
    }
}
