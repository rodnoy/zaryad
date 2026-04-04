import Foundation

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var pollIntervalSeconds: Int = 2

    public init() {}
}
