import Data
import Domain
import SwiftUI

/// Sessions comparison table matching the web dashboard.
/// Shows 7 columns: Charger, Duration, Peak W, Avg W, +% Charge, Avg Temp, Rating.
/// Best row (highest avgW) is highlighted.
public struct SessionsComparisonView: View {
    @EnvironmentObject var sessionsVM: SessionsViewModel
    @EnvironmentObject var realtime: RealtimeViewModel
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var showNameInput = false
    @State private var sessionName = ""

    public init() {}

    public var body: some View {
        let p = themeStore.current.palette
        let headerColor = p.muted.opacity(0.88)

        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("sessions.title")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(headerColor)
                        .tracking(1)
                    Text("sessions.subtitle")
                        .font(.system(size: 12))
                        .foregroundColor(p.muted)
                }

                Spacer()

                HStack(spacing: 8) {
                    if realtime.isSessionActive {
                        recordingBadge
                        Button(action: {
                            Task { await realtime.stopSession() }
                        }) {
                            Text("sessions.button.stop")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(p.red, lineWidth: 1)
                                )
                                .foregroundColor(p.red)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("sessions.button.stop")
                    } else {
                        Button(action: {
                            sessionName = String(
                                format: String(localized: "sessions.default_name.format"),
                                sessionsVM.sessions.count + 1
                            )
                            showNameInput = true
                        }) {
                            Text("sessions.button.record")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(p.accent)
                                )
                                .foregroundColor(p.text)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("sessions.button.record")
                    }

                    if !sessionsVM.sessions.isEmpty {
                        Menu {
                            Button("sessions.button.export_selected_csv") { sessionsVM.exportSelectedSessionsCSV() }
                            Button("sessions.button.export_selected_json") { sessionsVM.exportSelectedSessionsJSON() }
                        } label: {
                            Text("sessions.button.export_selected")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(p.accent, lineWidth: 1)
                                )
                                .foregroundColor(p.accent)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .accessibilityLabel("sessions.button.export_selected")

                        Menu {
                            Button("sessions.button.export_all_csv") { sessionsVM.exportAllSessionsCSV() }
                            Button("sessions.button.export_all_json") { sessionsVM.exportAllSessionsJSON() }
                        } label: {
                            Text("sessions.button.export_all")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(p.accent, lineWidth: 1)
                                )
                                .foregroundColor(p.accent)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .accessibilityLabel("sessions.button.export_all")

                        Button(action: {
                            sessionsVM.importSessionsJSON()
                        }) {
                            Text("sessions.button.import")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(p.accent, lineWidth: 1)
                                )
                                .foregroundColor(p.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("sessions.button.import")

                        Button(action: {
                            Task { await sessionsVM.deleteAll() }
                        }) {
                            Text("sessions.button.clear")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(p.red, lineWidth: 1)
                                )
                                .foregroundColor(p.red)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("sessions.button.clear")
                    }
                }
            }
            .padding(.bottom, 16)

            if sessionsVM.sessions.isEmpty && !realtime.isSessionActive {
                emptyState
            } else {
                VStack(spacing: 16) {
                    SessionBarChartView(sessions: sessionsVM.sessions)
                    sessionsTable
                }
            }
        }
        .cardStyle()
        .alert("sessions.alert.title", isPresented: $showNameInput) {
            TextField(String(localized: "sessions.alert.textfield.placeholder"), text: $sessionName)
            Button("sessions.alert.button.start") {
                Task { await realtime.startSession(name: sessionName) }
            }
            Button("btn.cancel", role: .cancel) {}
        } message: {
            Text("sessions.alert.message")
        }
        .alert(item: $sessionsVM.exportStatus) { status in
            Alert(
                title: Text(status.titleKey),
                message: Text(status.message),
                dismissButton: .default(Text("btn.cancel")) {
                    sessionsVM.exportStatus = nil
                }
            )
        }
    }

    // MARK: - Recording badge

    private var recordingBadge: some View {
        let p = themeStore.current.palette

        return HStack(spacing: 6) {
            Circle()
                .fill(p.green)
                .frame(width: 8, height: 8)
            Text("sessions.recording")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(p.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(p.green.opacity(0.08))
                .stroke(p.green.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        let p = themeStore.current.palette

        return VStack(spacing: 4) {
            Text("sessions.empty.title")
                .font(.system(size: 13))
                .foregroundColor(p.muted)
            Text("sessions.empty.subtitle")
                .font(.system(size: 13))
                .foregroundColor(p.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Sessions table

    private var sessionsTable: some View {
        let bestID = sessionsVM.bestSession?.id
        let p = themeStore.current.palette

        return VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                tableHeader("", flex: 0)
                tableHeader("sessions.table.header.charger", flex: 2)
                tableHeader("sessions.table.header.duration", flex: 1)
                tableHeader("sessions.table.header.peak_w", flex: 1)
                tableHeader("sessions.table.header.avg_w", flex: 1)
                tableHeader("sessions.table.header.delta_charge", flex: 1)
                tableHeader("sessions.table.header.avg_temp", flex: 1)
                tableHeader("sessions.table.header.rating", flex: 1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .overlay(alignment: .bottom) {
                Rectangle().fill(p.border).frame(height: 1)
            }

            // Table rows
            ForEach(sessionsVM.sessions) { session in
                let isBest = session.id == bestID
                sessionRow(session, isBest: isBest)
            }
        }
    }

    @ViewBuilder
    private func tableHeader(_ title: String, flex: Int) -> some View {
        let headerColor = themeStore.current.palette.muted.opacity(0.88)

        Text(NSLocalizedString(title, comment: "").uppercased())
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(headerColor)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(Double(flex))
    }

    @ViewBuilder
    private func sessionRow(_ session: Session, isBest: Bool) -> some View {
        let p = themeStore.current.palette
        let color = isBest ? p.green : p.text

        HStack(spacing: 0) {
            Button(action: { sessionsVM.toggleSelection(session.id) }) {
                Image(systemName: sessionsVM.selectedSessionIDs.contains(session.id) ? "checkmark.square.fill" : "square")
                    .foregroundColor(sessionsVM.selectedSessionIDs.contains(session.id) ? p.accent : p.muted)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 22, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("sessions.select_row")

            // Charger name + BEST tag
            HStack(spacing: 6) {
                Text(session.name ?? String(localized: "sessions.session.fallback_name"))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(color)
                    .lineLimit(1)
                if isBest {
                    Text("sessions.badge.best")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(p.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(p.green.opacity(0.15))
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(2)

            Text(formatDuration(session.duration))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(session.peakW.map { String(format: "%.1fW", $0) } ?? String(localized: "common.value.unknown"))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(session.avgW.map { String(format: "%.1fW", $0) } ?? String(localized: "common.value.unknown"))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(String(format: "%+.1f%%", session.deltaPercent))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(session.avgTemp.map { String(format: "%.1f°C", $0) } ?? String(localized: "common.value.unknown"))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            ratingTag(session.rating)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.border).frame(height: 1)
        }
    }

    @ViewBuilder
    private func ratingTag(_ rating: SessionRating) -> some View {
        let p = themeStore.current.palette

        let titleKey: String = {
            switch rating {
            case .excellent: return "session.rating.excellent"
            case .good: return "session.rating.good"
            case .fair: return "session.rating.fair"
            case .poor: return "session.rating.poor"
            case .unknown: return "session.rating.unknown"
            }
        }()

        let (bgColor, fgColor): (Color, Color) = {
            switch rating {
            case .excellent: return (p.green.opacity(0.15), p.green)
            case .good: return (p.yellow.opacity(0.15), p.yellow)
            case .fair: return (p.surface2, p.muted)
            case .poor: return (p.red.opacity(0.15), p.red)
            case .unknown: return (p.surface2, p.muted)
            }
        }()

        Text(titleKey)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(fgColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(bgColor)
            )
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s >= 60 {
            return String(format: String(localized: "sessions.duration.minutes_seconds.format"), s / 60, s % 60)
        }
        return String(format: String(localized: "sessions.duration.seconds.format"), s)
    }
}
