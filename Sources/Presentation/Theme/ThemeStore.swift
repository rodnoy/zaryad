import Data
import Domain
import Foundation
import os
import SwiftUI

@MainActor
public final class ThemeStore: ObservableObject {
    // Shared singleton instance used by AppTheme and DI so there's a single
    // source of truth for the currently selected theme across the app.
    public static let shared = ThemeStore()

    public static var all: [Theme] { shared.allThemes }

    @Published public var current: Theme
    @Published public private(set) var allThemes: [Theme]

    private let userDefaults: UserDefaults
    private let loader: ThemeLoader
    private let fileManager: FileManager
    private let selectedThemeKey = "selectedTheme"
    private let logger = Logger(subsystem: "com.chargermonitor", category: "ThemeStore")
    private var directoryWatcher: ThemeDirectoryWatcher?

    public var currentKey: String {
        current.key
    }

    public var selectedKey: String {
        get { current.key }
        set { select(key: newValue) }
    }

    public init(
        userDefaults: UserDefaults = .standard,
        loader: ThemeLoader = ThemeLoader(),
        fileManager: FileManager = .default
    ) {
        self.userDefaults = userDefaults
        self.loader = loader
        self.fileManager = fileManager

        let loadedThemes = loader.loadAllThemes()
        let resolvedThemes = loadedThemes.isEmpty ? Theme.builtInThemes : loadedThemes
        self.allThemes = resolvedThemes

        let key = userDefaults.string(forKey: selectedThemeKey) ?? Theme.dark.key
        self.current = resolvedThemes.first(where: { $0.key == key }) ?? Theme.dark

        startWatchingUserThemesDirectory()
    }

    deinit {
        directoryWatcher?.stop()
    }

    // MARK: - Theme Import

    public enum ImportError: LocalizedError {
        case readFailed(URL)
        case invalidTheme
        case alreadyExists(String)

        public var errorDescription: String? {
            switch self {
            case .readFailed(let url):
                return "Failed to read file: \(url.lastPathComponent)"
            case .invalidTheme:
                return String(localized: "settings.theme.import.error.invalid")
            case .alreadyExists(let key):
                return String(localized: "settings.theme.import.error.exists") + " (\(key))"
            }
        }
    }

    @discardableResult
    public func importTheme(from sourceURL: URL) throws -> Theme {
        // 1. Read JSON data
        let data: Foundation.Data
        do {
            data = try Foundation.Data(contentsOf: sourceURL)
        } catch {
            logger.error("Failed to read theme file: \(sourceURL.lastPathComponent, privacy: .public)")
            throw ImportError.readFailed(sourceURL)
        }

        // 2. Decode & validate
        let decoder = JSONDecoder()
        let dto: ThemeDTO
        do {
            dto = try decoder.decode(ThemeDTO.self, from: data)
        } catch {
            logger.error("Failed to decode theme file: \(error.localizedDescription, privacy: .public)")
            throw ImportError.invalidTheme
        }

        guard dto.validate() else {
            logger.error("Theme validation failed for key: \(dto.key, privacy: .public)")
            throw ImportError.invalidTheme
        }

        guard let theme = dto.toTheme() else {
            throw ImportError.invalidTheme
        }

        // 3. Check for duplicates
        let destination = loader.userThemesDirectoryURL()
            .appendingPathComponent("\(dto.key).json")

        if fileManager.fileExists(atPath: destination.path) {
            throw ImportError.alreadyExists(dto.key)
        }

        // 4. Ensure directory exists & copy
        ensureUserThemesDirectoryExists()
        try data.write(to: destination, options: .atomic)

        // 5. Reload and select the new theme
        reload()
        select(key: theme.key)

        logger.info("Theme imported successfully: \(theme.key, privacy: .public)")
        return theme
    }

    public func select(key: String) {
        let theme = allThemes.first(where: { $0.key == key }) ?? Theme.dark
        guard current.key != theme.key else { return }
        UserDefaults.standard.set(key, forKey: "selectedTheme")
        setCurrent(theme, animated: true)
    }

    public func reload() {
        let loadedThemes = loader.loadAllThemes()
        allThemes = loadedThemes.isEmpty ? Theme.builtInThemes : loadedThemes

        let persistedKey = userDefaults.string(forKey: selectedThemeKey) ?? current.key
        if let next = allThemes.first(where: { $0.key == persistedKey }) {
            if current.key != next.key {
                setCurrent(next, animated: true)
            }
        } else {
            setCurrent(Theme.dark, animated: true)
            userDefaults.set(Theme.dark.key, forKey: selectedThemeKey)
        }

        ensureDirectoryWatcherIsRunning()
    }

    private func startWatchingUserThemesDirectory() {
        ensureUserThemesDirectoryExists()
        ensureDirectoryWatcherIsRunning()
    }

    private func ensureDirectoryWatcherIsRunning() {
        guard directoryWatcher == nil else { return }

        let userThemesDirectory = loader.userThemesDirectoryURL()
        let watcher = ThemeDirectoryWatcher(directoryURL: userThemesDirectory) { [weak self] in
            DispatchQueue.main.async {
                self?.reload()
            }
        }
        watcher.start()
        self.directoryWatcher = watcher
    }

    private func ensureUserThemesDirectoryExists() {
        let userThemesDirectory = loader.userThemesDirectoryURL()
        try? fileManager.createDirectory(at: userThemesDirectory, withIntermediateDirectories: true)
    }

    private func setCurrent(_ theme: Theme, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                self.current = theme
            }
        } else {
            self.current = theme
        }
    }
}
