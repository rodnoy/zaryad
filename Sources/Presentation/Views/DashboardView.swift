import Data
import Domain
import SwiftUI
import os

private let logger = Logger(subsystem: "com.chargermonitor", category: "DashboardView")

/// Main dashboard view matching the web charger_dashboard.html layout.
public struct DashboardView: View {
    @EnvironmentObject var realtime: RealtimeViewModel
    @EnvironmentObject var sessionsVM: SessionsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var themeStore: ThemeStore

    @State private var showingSettings = false
    @State private var showTemperatureOverlay = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView

                // 4-column metrics row
                metricsRow

                // Power chart (full width)
                PowerChartView(
                    samples: realtime.recentSamples,
                    showTemperatureOverlay: showTemperatureOverlay,
                    onToggleTemperatureOverlay: { showTemperatureOverlay.toggle() }
                )

                // Second row: Battery + Battery Health
                HStack(alignment: .top, spacing: 16) {
                    BatteryCardView(sample: realtime.currentSample)
                    BatteryHealthView(sample: realtime.currentSample)
                }

                // Sessions comparison table
                SessionsComparisonView()

                // Footer
                footerView
            }
            .padding(24)
        }
        .background(AppTheme.bg)
        .onAppear {
            logger.info("Dashboard appeared, starting polling")
            Task {
                await realtime.startPolling(pollIntervalSeconds: UInt64(settingsVM.pollIntervalSeconds))
                await sessionsVM.reload()
            }
        }
        .onDisappear {
            logger.info("Dashboard disappeared, stopping polling")
            Task { await realtime.stopPolling() }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settingsVM)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            HStack(spacing: 12) {
                // Logo icon
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accent2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("⚡")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.surface)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 0) {
                        Text("dashboard.header.brand.charger")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.text)
                        Text("dashboard.header.brand.monitor")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.accent)
                    }
                    Text("dashboard.header.subtitle")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.muted)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // Settings button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.muted)
                }
                .buttonStyle(.plain)

                statusPill
            }
        }
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.border).frame(height: 1)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusDotColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(AppTheme.mono(size: 12))
                .foregroundColor(AppTheme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppTheme.surface)
                .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
        )
    }

    private var statusDotColor: Color {
        switch realtime.connectionStatus {
        case .connected: return AppTheme.green
        case .disconnected: return AppTheme.muted
        case .error: return AppTheme.red
        }
    }

    private var statusText: String {
        switch realtime.connectionStatus {
        case .connected: return String(localized: "dashboard.status.live_stream")
        case .disconnected: return String(localized: "dashboard.status.connecting")
        case .error: return String(localized: "dashboard.status.no_connection")
        }
    }

    // MARK: - Metrics Row

    private var metricsRow: some View {
        let sample = realtime.currentSample
        let powerW = sample?.powerW ?? 0

        return HStack(spacing: 16) {
            MetricCardView(
                label: "dashboard.metrics.power.label",
                value: String(format: "%.1f", abs(powerW)),
                unit: "W",
                subtitle: powerSubtitle(sample),
                valueColor: powerW > 0.5 ? AppTheme.green : powerW < -0.5 ? AppTheme.yellow : AppTheme.muted
            )

            MetricCardView(
                label: "dashboard.metrics.voltage.label",
                value: String(format: "%.2f", sample?.voltageV ?? 0),
                unit: "V",
                subtitle: (sample?.pluggedIn == true)
                    ? String(localized: "dashboard.metrics.voltage.subtitle.power_connected")
                    : String(localized: "dashboard.metrics.voltage.subtitle.on_battery")
            )

            MetricCardView(
                label: "dashboard.metrics.current.label",
                value: String(format: "%.2f", abs(sample?.amperageA ?? 0)),
                unit: "A",
                subtitle: (sample?.amperageA ?? 0) >= 0
                    ? String(localized: "dashboard.metrics.current.subtitle.into_battery")
                    : String(localized: "dashboard.metrics.current.subtitle.from_battery")
            )

            MetricCardView(
                label: "dashboard.metrics.temperature.label",
                value: String(format: "%.1f", sample?.tempC ?? 0),
                unit: "°C",
                subtitle: tempSubtitle(sample?.tempC)
            )
        }
    }

    private func powerSubtitle(_ sample: BatterySample?) -> String {
        guard let s = sample else { return String(localized: "dashboard.metrics.power.subtitle.waiting_data") }
        let pw = s.powerW ?? 0
        if pw > 0.5 {
            let adapter = s.adapterWatts.map { "\(Int($0))W" } ?? "?"
            return String(format: String(localized: "dashboard.metrics.power.subtitle.charging_adapter_format"), adapter)
        } else if pw < -0.5 {
            return String(localized: "dashboard.metrics.power.subtitle.discharge_battery")
        } else {
            return String(localized: "dashboard.metrics.power.subtitle.connected_full")
        }
    }

    private func tempSubtitle(_ temp: Double?) -> String {
        guard let t = temp else { return String(localized: "common.value.unknown") }
        if t > 40 { return String(localized: "dashboard.metrics.temperature.subtitle.hot") }
        if t > 35 { return String(localized: "dashboard.metrics.temperature.subtitle.warm") }
        return String(localized: "dashboard.metrics.temperature.subtitle.normal")
    }

    // MARK: - Footer

    private var footerView: some View {
        Text("dashboard.footer.data_source")
            .font(AppTheme.mono(size: 12))
            .foregroundColor(AppTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .overlay(alignment: .top) {
                Rectangle().fill(AppTheme.border).frame(height: 1)
            }
    }
}
