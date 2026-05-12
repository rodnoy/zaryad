import Foundation
import XCTest

/// Verifies that no localization value equals its own key (raw key leak) and no value is empty.
final class LocalizationCompletenessTests: XCTestCase {

    func testNoValueEqualsItsKey() throws {
        let locales = ["en", "ru", "fr"]
        for locale in locales {
            let entries = try parseEntries(locale: locale)
            XCTAssertFalse(entries.isEmpty, "\(locale).lproj should have entries")

            for (key, value) in entries {
                XCTAssertNotEqual(key, value, "\(locale).lproj: value for '\(key)' equals the key itself (raw key leak)")
            }
        }
    }

    func testNoValueIsEmpty() throws {
        let locales = ["en", "ru", "fr"]
        for locale in locales {
            let entries = try parseEntries(locale: locale)
            for (key, value) in entries {
                XCTAssertFalse(value.isEmpty, "\(locale).lproj: value for '\(key)' is empty")
            }
        }
    }

    func testNoValueContainsOnlyWhitespace() throws {
        let locales = ["en", "ru", "fr"]
        for locale in locales {
            let entries = try parseEntries(locale: locale)
            for (key, value) in entries {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                // Allow "—" as a valid placeholder value
                if trimmed != "—" {
                    XCTAssertFalse(trimmed.isEmpty, "\(locale).lproj: value for '\(key)' is only whitespace")
                }
            }
        }
    }

    // MARK: - Helpers

    private func parseEntries(locale: String) throws -> [(key: String, value: String)] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let path = root.appendingPathComponent("Resources/\(locale).lproj/Localizable.strings").path
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let pattern = #"^\s*"([^"]+)"\s*=\s*"([^"]*)"\s*;\s*$"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        let ns = content as NSString

        var entries: [(key: String, value: String)] = []
        for match in regex.matches(in: content, options: [], range: NSRange(location: 0, length: ns.length)) {
            guard match.numberOfRanges > 2 else { continue }
            let key = ns.substring(with: match.range(at: 1))
            let value = ns.substring(with: match.range(at: 2))
            entries.append((key: key, value: value))
        }
        return entries
    }
}
