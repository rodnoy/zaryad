import Foundation

@MainActor
public final class ThemeStore: ObservableObject {
    // Shared singleton instance used by AppTheme and DI so there's a single
    // source of truth for the currently selected theme across the app.
    public static let shared = ThemeStore()

    public static let all: [Theme] = [.dark, .light, .forest, .marine, .martian]

    @Published public var current: Theme
    private let userDefaults: UserDefaults

    public var currentKey: String {
        current.key
    }

    public var selectedKey: String {
        get { current.key }
        set { select(key: newValue) }
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let key = userDefaults.string(forKey: "selectedTheme") ?? Theme.dark.key
        self.current = Theme.forKey(key)
    }

    public func select(key: String) {
        let next = Theme.forKey(key)
        guard current.key != next.key else { return }
        userDefaults.set(next.key, forKey: "selectedTheme")
        current = next
    }
}
