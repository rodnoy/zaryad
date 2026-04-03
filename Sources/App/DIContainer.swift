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
}
