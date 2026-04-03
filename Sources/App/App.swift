import SwiftUI
import Presentation

@main
struct ChargerMonitorApp: App {
    @StateObject private var di = DIContainer()

    var body: some Scene {
        WindowGroup("Charger Monitor") {
            Presentation.DashboardView()
                .environmentObject(di.realtimeViewModel)
                .environmentObject(di.sessionsViewModel)
                .environmentObject(di.settingsViewModel)
        }
    }
}
