import Foundation
import XCTest

final class ThemeMigrationTests: XCTestCase {
    func testThemeExportCreatesThemeJSONFilesAndBackup() throws {
        let fileManager = FileManager.default
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repoRoot.appendingPathComponent("scripts/theme_export.swift")

        XCTAssertTrue(fileManager.fileExists(atPath: scriptURL.path))

        let tempRoot = fileManager.temporaryDirectory
            .appendingPathComponent("ThemeMigrationTests-\(UUID().uuidString)", isDirectory: true)
        let sourceThemeDir = tempRoot.appendingPathComponent("Sources/Presentation/Theme", isDirectory: true)
        let resourcesThemesDir = tempRoot.appendingPathComponent("Resources/Themes", isDirectory: true)

        try fileManager.createDirectory(at: sourceThemeDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: resourcesThemesDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let originalThemeSwift = sourceThemeDir.appendingPathComponent("Theme.swift")
        try "// test theme source".write(to: originalThemeSwift, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", scriptURL.path]
        process.currentDirectoryURL = tempRoot

        let stdOut = Pipe()
        let stdErr = Pipe()
        process.standardOutput = stdOut
        process.standardError = stdErr

        try process.run()
        process.waitUntilExit()

        let outputData = stdOut.fileHandleForReading.readDataToEndOfFile()
        let errorData = stdErr.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""

        XCTAssertEqual(process.terminationStatus, 0, "theme_export.swift failed. stderr: \(error)")
        XCTAssertTrue(output.contains("Backed up Theme.swift"))

        let generatedThemeFiles = ["dark.json", "light.json", "forest.json", "marine.json", "martian.json"]
        for filename in generatedThemeFiles {
            XCTAssertTrue(
                fileManager.fileExists(atPath: resourcesThemesDir.appendingPathComponent(filename).path),
                "Expected generated file \(filename)"
            )
        }

        let sourceDirContents = try fileManager.contentsOfDirectory(
            at: sourceThemeDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let backupFiles = sourceDirContents.filter { $0.lastPathComponent.hasPrefix("Theme.swift.backup.") }
        XCTAssertEqual(backupFiles.count, 1)
    }
}
