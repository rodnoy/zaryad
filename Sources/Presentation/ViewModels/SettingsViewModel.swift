import Foundation

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var pollIntervalSeconds: Int = 2
    @Published public var useSwiftData: Bool = false
    @Published public var useLocalHTTPExporter: Bool = false

    public init() {}
}
