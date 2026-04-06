#!/usr/bin/env swift

import Foundation

struct LocalizationCheckError: Error, CustomStringConvertible {
    let description: String
}

func parseKeys(from path: String) throws -> Set<String> {
    let content = try String(contentsOfFile: path, encoding: .utf8)
    let pattern = #"^\s*"([^"]+)"\s*=\s*".*"\s*;\s*$"#
    let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
    let ns = content as NSString

    var keys = Set<String>()
    for match in regex.matches(in: content, options: [], range: NSRange(location: 0, length: ns.length)) {
        guard match.numberOfRanges > 1 else { continue }
        let key = ns.substring(with: match.range(at: 1))
        keys.insert(key)
    }
    return keys
}

do {
    let baseDir = FileManager.default.currentDirectoryPath
    let enPath = "\(baseDir)/Resources/en.lproj/Localizable.strings"
    let ruPath = "\(baseDir)/Resources/ru.lproj/Localizable.strings"
    let frPath = "\(baseDir)/Resources/fr.lproj/Localizable.strings"

    let en = try parseKeys(from: enPath)
    let ru = try parseKeys(from: ruPath)
    let fr = try parseKeys(from: frPath)

    if en.isEmpty {
        throw LocalizationCheckError(description: "No keys parsed from en.lproj/Localizable.strings")
    }

    let missingInRu = en.subtracting(ru).sorted()
    let missingInFr = en.subtracting(fr).sorted()
    let extraInRu = ru.subtracting(en).sorted()
    let extraInFr = fr.subtracting(en).sorted()

    var hasErrors = false

    if !missingInRu.isEmpty {
        hasErrors = true
        print("Missing in ru.lproj:")
        missingInRu.forEach { print("  - \($0)") }
    }

    if !missingInFr.isEmpty {
        hasErrors = true
        print("Missing in fr.lproj:")
        missingInFr.forEach { print("  - \($0)") }
    }

    if !extraInRu.isEmpty {
        hasErrors = true
        print("Extra in ru.lproj (not present in en.lproj):")
        extraInRu.forEach { print("  - \($0)") }
    }

    if !extraInFr.isEmpty {
        hasErrors = true
        print("Extra in fr.lproj (not present in en.lproj):")
        extraInFr.forEach { print("  - \($0)") }
    }

    if hasErrors {
        exit(1)
    }

    print("Localization key check passed: \(en.count) keys in en/ru/fr")
} catch {
    fputs("Localization check failed: \(error)\n", stderr)
    exit(1)
}
