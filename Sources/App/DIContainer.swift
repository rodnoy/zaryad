import Presentation
import Domain
import Data
import Foundation
import SwiftData
import Combine

@MainActor
final class DIContainer: ObservableObject {
    let modelContainer: ModelContainer
    let powerRepository: any SystemPowerRepository
    let sessionStore: any SessionStoreProtocol
    let poller: BatteryPoller
    let sessionManager: SessionManager
    let themeStore: ThemeStore

    let realtimeViewModel: RealtimeViewModel
    let sessionsViewModel: SessionsViewModel
    let settingsViewModel: SettingsViewModel

    private var cancellables = Set<AnyCancellable>()

    init() {
        // SwiftData model container
        let schema = Schema([SDSession.self])
        let config = ModelConfiguration("ChargerMonitor", isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: [config])
        self.modelContainer = container

        // Data layer
        self.powerRepository = IOKitBatteryRepository()
        self.sessionStore = SwiftDataSessionStore(modelContainer: container)
        self.poller = BatteryPoller(repository: self.powerRepository)
        self.sessionManager = SessionManager(store: self.sessionStore)
        // Use the shared ThemeStore so it's the same instance used by AppTheme
        // and any other global consumers.
        self.themeStore = ThemeStore.shared

        // Presentation
        self.realtimeViewModel = RealtimeViewModel(
            poller: self.poller,
            sessionManager: self.sessionManager
        )
        self.sessionsViewModel = SessionsViewModel(sessionManager: self.sessionManager)
        self.settingsViewModel = SettingsViewModel()

        // When session stops, refresh sessions list
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
