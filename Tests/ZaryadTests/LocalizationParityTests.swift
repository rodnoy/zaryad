import Foundation
import XCTest

final class LocalizationParityTests: XCTestCase {
    func testLocalizationKeysAreInSyncAcrossEnRuFr() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let enPath = root.appendingPathComponent("Resources/en.lproj/Localizable.strings").path
        let ruPath = root.appendingPathComponent("Resources/ru.lproj/Localizable.strings").path
        let frPath = root.appendingPathComponent("Resources/fr.lproj/Localizable.strings").path

        let en = try parseKeys(from: enPath)
        let ru = try parseKeys(from: ruPath)
        let fr = try parseKeys(from: frPath)

        XCTAssertFalse(en.isEmpty, "Expected non-empty en.lproj localization keys")

        XCTAssertEqual(ru.subtracting(en), [], "ru has extra keys not in en")
        XCTAssertEqual(fr.subtracting(en), [], "fr has extra keys not in en")
        XCTAssertEqual(en.subtracting(ru), [], "ru is missing keys from en")
        XCTAssertEqual(en.subtracting(fr), [], "fr is missing keys from en")
    }

    private func parseKeys(from path: String) throws -> Set<String> {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let pattern = #"^\s*"([^"]+)"\s*=\s*".*"\s*;\s*$"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        let ns = content as NSString

        var keys = Set<String>()
        for match in regex.matches(in: content, options: [], range: NSRange(location: 0, length: ns.length)) {
            guard match.numberOfRanges > 1 else { continue }
            keys.insert(ns.substring(with: match.range(at: 1)))
        }
        return keys
    }
}
