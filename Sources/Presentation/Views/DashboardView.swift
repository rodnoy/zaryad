import SwiftUI
import Domain
import Data


public enum Presentation { }

extension Presentation {
    public struct DashboardView: View {
        @EnvironmentObject var realtime: RealtimeViewModel
        @EnvironmentObject var sessionsVM: SessionsViewModel
        @EnvironmentObject var settingsVM: SettingsViewModel

        @State private var showingSessions: Bool = false
        @State private var showingSettings: Bool = false

        public init() {}

        public var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Presentation.BatteryCardView(sample: realtime.currentSample)
                        .frame(width: 220, height: 140)

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Realtime")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Button(action: { Task { await realtime.toggleSession() } }) {
                                Text(realtime.isSessionActive ? "Stop Session" : "Start Session")
                            }
                        }

                        if let sample = realtime.currentSample {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("Power: \(sample.powerW.map { String(format: "%.1f W", $0) } ?? "—")")
                                    Text("Voltage: \(sample.voltageV.map { String(format: "%.2f V", $0) } ?? "—")")
                                }
                                VStack(alignment: .leading) {
                                    Text("Amperage: \(sample.amperageA.map { String(format: "%.2f A", $0) } ?? "—")")
                                    Text("Temp: \(sample.tempC.map { String(format: "%.1f °C", $0) } ?? "—")")
                                }
                            }
                        } else {
                            Text("No data yet")
                                .foregroundColor(.secondary)
                        }

                        Presentation.PowerChartView(samples: realtime.recentSamples)
                            .frame(height: 200)
                    }
                }
                .padding()

                HStack {
                    Button(action: { showingSessions.toggle() }) { Text("Sessions") }
                    Button(action: { showingSettings.toggle() }) { Text("Settings") }
                    Spacer()
                    Presentation.SessionsSummaryView(latest: sessionsVM.latestSession)
                }
                .padding()

                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingSessions) {
                Presentation.SessionsListView()
                    .environmentObject(sessionsVM)
            }
            .sheet(isPresented: $showingSettings) {
                Presentation.SettingsView()
                    .environmentObject(settingsVM)
            }
            .onAppear {
                Task {
                    await realtime.startPolling(pollIntervalSeconds: UInt64(settingsVM.pollIntervalSeconds))
                    await sessionsVM.reload()
                }
            }
            .onDisappear { realtime.stopPolling() }
        }
    }
}
