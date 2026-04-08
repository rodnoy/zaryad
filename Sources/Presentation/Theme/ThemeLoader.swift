import Data
import Domain
import Foundation
import os

public struct ThemeLoader {
    private let logger = Logger(subsystem: "com.chargermonitor", category: "ThemeLoader")
    private let fileManager: FileManager
    private let bundle: Bundle
    private let customBuiltInThemesDirectoryURL: URL?
    private let customUserThemesDirectoryURL: URL?

    public init(
        fileManager: FileManager = .default,
        bundle: Bundle = .main,
        builtInThemesDirectoryURL: URL? = nil,
        userThemesDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.bundle = bundle
        self.customBuiltInThemesDirectoryURL = builtInThemesDirectoryURL
        self.customUserThemesDirectoryURL = userThemesDirectoryURL
    }

    public func loadBuiltInThemes() -> [Theme] {
        if let customBuiltInThemesDirectoryURL {
            do {
                let urls = try fileManager.contentsOfDirectory(
                    at: customBuiltInThemesDirectoryURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
                let jsonURLs = urls.filter { $0.pathExtension.lowercased() == "json" }
                return loadThemes(from: jsonURLs)
            } catch {
                logger.error("Failed to enumerate built-in themes: \(error.localizedDescription, privacy: .public)")
                return []
            }
        }

        guard let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: "Themes") else {
            logger.info("No built-in theme JSON files found in bundle")
            return []
        }

        return loadThemes(from: urls)
    }

    public func loadUserThemes() -> [Theme] {
        let userDir = userThemesDirectoryURL()
        guard fileManager.fileExists(atPath: userDir.path) else {
            return []
        }

        do {
            let urls = try fileManager.contentsOfDirectory(
                at: userDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            let jsonURLs = urls.filter { $0.pathExtension.lowercased() == "json" }
            return loadThemes(from: jsonURLs)
        } catch {
            logger.error("Failed to enumerate user themes: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    public func loadAllThemes() -> [Theme] {
        var merged = indexByKey(themes: Theme.builtInThemes)

        let builtIn = indexByKey(themes: loadBuiltInThemes())
        let user = indexByKey(themes: loadUserThemes())
        merged.merge(builtIn) { _, loaded in loaded }
        merged.merge(user) { _, loaded in loaded }

        if merged.isEmpty {
            return Theme.builtInThemes
        }

        var ordered: [Theme] = []
        var seen = Set<String>()

        for key in Theme.builtInThemes.map(\.key) {
            if let theme = merged[key] {
                ordered.append(theme)
                seen.insert(key)
            }
        }

        for key in merged.keys.sorted() where !seen.contains(key) {
            if let theme = merged[key] {
                ordered.append(theme)
            }
        }

        return ordered.isEmpty ? Theme.builtInThemes : ordered
    }

    public func userThemesDirectoryURL() -> URL {
        if let customUserThemesDirectoryURL {
            return customUserThemesDirectoryURL
        }

        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".chargermonitor", isDirectory: true)
            .appendingPathComponent("themes", isDirectory: true)
    }

    private func loadThemes(from urls: [URL]) -> [Theme] {
        var result: [Theme] = []
        let decoder = JSONDecoder()

        for url in urls {
            do {
                let data = try Foundation.Data(contentsOf: url)
                let dto = try decoder.decode(ThemeDTO.self, from: data)

                guard let theme = dto.toTheme() else {
                    logger.error("Skipped invalid theme JSON: \(url.lastPathComponent, privacy: .public)")
                    continue
                }

                result.append(theme)
            } catch {
                logger.error("Failed to load theme JSON \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        return result
    }

    private func indexByKey(themes: [Theme]) -> [String: Theme] {
        var indexed: [String: Theme] = [:]
        for theme in themes {
            indexed[theme.key] = theme
        }
        return indexed
    }
}
