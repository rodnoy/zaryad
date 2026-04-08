import Data
import Domain
import Foundation

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

    public func select(key: String) {
        let next = allThemes.first(where: { $0.key == key }) ?? Theme.dark
        guard current.key != next.key else { return }
        userDefaults.set(next.key, forKey: selectedThemeKey)
        current = next
    }

    public func reload() {
        let loadedThemes = loader.loadAllThemes()
        allThemes = loadedThemes.isEmpty ? Theme.builtInThemes : loadedThemes

        let persistedKey = userDefaults.string(forKey: selectedThemeKey) ?? current.key
        if let next = allThemes.first(where: { $0.key == persistedKey }) {
            current = next
        } else {
            current = Theme.dark
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
}
