import SwiftUI
import SwiftData

@main
struct ChargerMonitorApp: App {
    @StateObject private var di = DIContainer()

    var body: some Scene {
        WindowGroup("Charger Monitor") {
            DashboardView()
                .environmentObject(di.realtimeViewModel)
                .environmentObject(di.sessionsViewModel)
                .environmentObject(di.settingsViewModel)
                .modelContainer(di.modelContainer)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 800)
    }
}
