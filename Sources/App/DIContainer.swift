import Foundation
import Data
import Presentation
import Combine

@MainActor
final class DIContainer: ObservableObject {
    // Data layer
    let powerRepository: DataLayer.SystemPower.SystemPowerRepository
    let sessionStore: DataLayer.SessionStore.SessionStore
    let poller: DataLayer.Poller.CentralPoller

    // Presentation
    let realtimeViewModel: RealtimeViewModel
    let sessionsViewModel: SessionsViewModel
    let settingsViewModel: SettingsViewModel

    // Local HTTP exporter
    private var exporter: LocalHTTPExporter?
    private var cancellables = Set<AnyCancellable>()

    init(
        powerRepository: DataLayer.SystemPower.SystemPowerRepository? = nil,
        session_store: DataLayer.SessionStore.SessionStore? = nil
    ) {
        // Default implementations (stubs) — replace with real implementations later
        self.powerRepository = powerRepository ?? DataLayer.SystemPower.ShellSystemPowerRepository()
        self.sessionStore = session_store ?? DataLayer.SessionStore.FileSessionStore()

        self.poller = DataLayer.Poller.CentralPoller(repository: self.powerRepository)

        // Session manager provides Start/Append/Stop use cases
        let sessionManager = SessionManager(store: self.sessionStore)

        self.realtimeViewModel = RealtimeViewModel(
            poller: self.poller,
            startUseCase: sessionManager,
            appendUseCase: sessionManager,
            stopUseCase: sessionManager
        )
        self.sessionsViewModel = SessionsViewModel(store: self.sessionStore)
        self.settingsViewModel = SettingsViewModel()

        // Observe settings toggle for local HTTP exporter
        self.settingsViewModel.$useLocalHTTPExporter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                Task { await self?.updateExporter(enabled: enabled) }
            }
            .store(in: &cancellables)

        // When sessions stop, refresh sessions list
        self.realtimeViewModel.$isSessionActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] active in
                if !active {
                    Task { await self?.sessionsViewModel.reload() }
                }
            }
            .store(in: &cancellables)
    }

    private func updateExporter(enabled: Bool) async {
        if enabled {
            // Build simple JSON provider capturing realtimeViewModel recentSamples
            let getJSON: () -> Data? = { [weak self] in
                guard let samples = self?.realtimeViewModel.recentSamples else { return nil }
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                return try? encoder.encode(samples)
            }

            // Prefer repository file in project root for dashboard HTML if available
            let cwd = FileManager.default.currentDirectoryPath
            let htmlPath = (cwd as NSString).appendingPathComponent("charger_dashboard.html")

            let exp = LocalHTTPExporter(port: 8080, htmlPath: htmlPath, getJSON: getJSON)
            do {
                try exp.start()
                self.exporter = exp
                print("Local HTTP exporter started on port 8080")
            } catch {
                print("Failed to start local HTTP exporter: \(error)")
            }
        } else {
            exporter?.stop()
            exporter = nil
            print("Local HTTP exporter stopped")
        }
    }
}
