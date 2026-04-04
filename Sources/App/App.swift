import SwiftUI
import SwiftData

@main
struct ChargerMonitorApp: App {
    @StateObject private var di = DIContainer()

    var body: some Scene {
        WindowGroup("app.title") {
            DashboardView()
                .environmentObject(di.realtimeViewModel)
                .environmentObject(di.sessionsViewModel)
                .environmentObject(di.settingsViewModel)
                .modelContainer(di.modelContainer)
        }
        .environmentObject(di.themeStore)
        .commands {
            ThemeCommands()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 800)
    }
}
