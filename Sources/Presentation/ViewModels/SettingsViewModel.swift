import Foundation

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var pollIntervalSeconds: Int = 2
    @Published public var useSwiftData: Bool = false
    // Removed web exporter flag: this app is native SwiftUI only.

    public init() {}
}
