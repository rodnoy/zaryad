import Presentation
import Domain
import Data
import Foundation
import SwiftData
import Combine
import os

private let logger = Logger(subsystem: "com.chargermonitor", category: "DIContainer")

@MainActor
final class DIContainer: ObservableObject {
    let modelContainer: ModelContainer
    let powerRepository: any SystemPowerRepository
    let sessionStore: any SessionStoreProtocol
    let healthSnapshotStore: HealthSnapshotStore
    let poller: BatteryPoller
    let sessionManager: SessionManager
    let themeStore: ThemeStore
    let recommendationEngine: RecommendationEngine

    let realtimeViewModel: RealtimeViewModel
    let sessionsViewModel: SessionsViewModel
    let settingsViewModel: SettingsViewModel
    let recommendationsViewModel: RecommendationsViewModel

    private var cancellables = Set<AnyCancellable>()

    init() {
        // SwiftData model container
        let schema = Schema([SDSession.self, SDHealthSnapshot.self])
        let config = ModelConfiguration("ChargerMonitor", isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            logger.error("Failed to create persistent ModelContainer: \(error.localizedDescription, privacy: .public)")
            do {
                let memoryConfig = ModelConfiguration("ChargerMonitorFallback", isStoredInMemoryOnly: true)
                container = try ModelContainer(for: schema, configurations: [memoryConfig])
                logger.warning("Using in-memory ModelContainer fallback")
            } catch {
                logger.fault("Failed to create in-memory ModelContainer fallback: \(error.localizedDescription, privacy: .public)")
                fatalError("Unable to initialize SwiftData ModelContainer")
            }
        }
        self.modelContainer = container

        // Data layer
        self.powerRepository = IOKitBatteryRepository()
        self.sessionStore = SwiftDataSessionStore(modelContainer: container)
        self.healthSnapshotStore = HealthSnapshotStore(modelContainer: container)
        self.poller = BatteryPoller(repository: self.powerRepository)
        self.sessionManager = SessionManager(store: self.sessionStore)
        // Use the shared ThemeStore so it's the same instance used by AppTheme
        // and any other global consumers.
        self.themeStore = ThemeStore.shared
        self.recommendationEngine = RecommendationEngine()

        // Presentation
        self.realtimeViewModel = RealtimeViewModel(
            poller: self.poller,
            sessionManager: self.sessionManager,
            healthSnapshotStore: self.healthSnapshotStore
        )
        self.sessionsViewModel = SessionsViewModel(sessionManager: self.sessionManager)
        self.settingsViewModel = SettingsViewModel()
        self.recommendationsViewModel = RecommendationsViewModel(
            realtimeViewModel: self.realtimeViewModel,
            sessionsViewModel: self.sessionsViewModel,
            recommendationEngine: self.recommendationEngine
        )

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
