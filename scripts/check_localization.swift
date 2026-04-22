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

// MARK: - Anti-pattern detection: Text(stringVariable) where variable is a String ending in "Key"

struct KeyAsValueWarning {
    let file: String
    let line: Int
    let match: String
}

func scanForKeyAsValueAntiPattern(in directory: String) -> [KeyAsValueWarning] {
    var warnings: [KeyAsValueWarning] = []
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(atPath: directory) else { return warnings }

    // Pattern: Text(<expr>) where <expr> is a variable/property access ending in "Key"
    // but NOT already wrapped in LocalizedStringKey(...)
    // Matches: Text(recommendation.titleKey), Text(titleKey), Text(item.messageKey)
    // Excludes: Text(LocalizedStringKey(...)), Text("literal")
    let dangerousPattern = try! NSRegularExpression(
        pattern: #"Text\((?!LocalizedStringKey)(?!")([a-zA-Z_][a-zA-Z0-9_.]*[Kk]ey)\)"#,
        options: []
    )

    while let relativePath = enumerator.nextObject() as? String {
        guard relativePath.hasSuffix(".swift"), !relativePath.contains(".bak") else { continue }
        let fullPath = (directory as NSString).appendingPathComponent(relativePath)
        guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else { continue }
        let lines = content.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            // Allow inline suppression: // localization-ok
            guard !line.contains("// localization-ok") else { continue }
            let ns = line as NSString
            let matches = dangerousPattern.matches(in: line, options: [], range: NSRange(location: 0, length: ns.length))
            for m in matches {
                let matchStr = ns.substring(with: m.range)
                warnings.append(KeyAsValueWarning(
                    file: relativePath,
                    line: index + 1,
                    match: matchStr
                ))
            }
        }
    }
    return warnings
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

    // MARK: - Scan Swift sources for Text(stringKey) anti-pattern
    let sourcesDir = "\(baseDir)/Sources"
    let antiPatternWarnings = scanForKeyAsValueAntiPattern(in: sourcesDir)
    if !antiPatternWarnings.isEmpty {
        hasErrors = true
        print("\n⚠️  Text(stringKey) anti-pattern detected (localization keys passed as plain String):")
        for w in antiPatternWarnings {
            print("  \(w.file):\(w.line): \(w.match)")
            // Suggest human-friendly default from key
            let keyExpr = w.match
                .replacingOccurrences(of: "Text(", with: "")
                .replacingOccurrences(of: ")", with: "")
            print("    → Wrap with LocalizedStringKey: Text(LocalizedStringKey(\(keyExpr)))")
        }
        exit(1)
    }

    print("Localization key check passed: \(en.count) keys in en/ru/fr")
} catch {
    fputs("Localization check failed: \(error)\n", stderr)
    exit(1)
}
