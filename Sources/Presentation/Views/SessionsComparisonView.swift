import Data
import Domain
import SwiftUI

/// Sessions comparison table matching the web dashboard.
/// Shows 7 columns: Charger, Duration, Peak W, Avg W, +% Charge, Avg Temp, Rating.
/// Best row (highest avgW) is highlighted.
public struct SessionsComparisonView: View {
    @EnvironmentObject var sessionsVM: SessionsViewModel
    @EnvironmentObject var realtime: RealtimeViewModel
    @State private var showNameInput = false
    @State private var sessionName = ""

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("sessions.title")
                        .font(AppTheme.mono(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.header)
                        .tracking(1)
                    Text("sessions.subtitle")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.muted)
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
                                        .stroke(AppTheme.red, lineWidth: 1)
                                )
                                .foregroundColor(AppTheme.red)
                        }
                        .buttonStyle(.plain)
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
                                        .fill(AppTheme.accent)
                                )
                                .foregroundColor(AppTheme.text)
                        }
                        .buttonStyle(.plain)
                    }

                    if !sessionsVM.sessions.isEmpty {
                        Button(action: {
                            sessionsVM.exportSelectedSessions()
                        }) {
                            Text("sessions.button.export_selected")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.accent, lineWidth: 1)
                                )
                                .foregroundColor(AppTheme.accent)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            sessionsVM.exportAllSessions()
                        }) {
                            Text("sessions.button.export_all")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.accent, lineWidth: 1)
                                )
                                .foregroundColor(AppTheme.accent)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            Task { await sessionsVM.deleteAll() }
                        }) {
                            Text("sessions.button.clear")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.red, lineWidth: 1)
                                )
                                .foregroundColor(AppTheme.red)
                        }
                        .buttonStyle(.plain)
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
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.green)
                .frame(width: 8, height: 8)
            Text("sessions.recording")
                .font(AppTheme.mono(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.green.opacity(0.08))
                .stroke(AppTheme.green.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("sessions.empty.title")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.muted)
            Text("sessions.empty.subtitle")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Sessions table

    private var sessionsTable: some View {
        let bestID = sessionsVM.bestSession?.id

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
                Rectangle().fill(AppTheme.border).frame(height: 1)
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
        Text(NSLocalizedString(title, comment: "").uppercased())
            .font(AppTheme.mono(size: 11, weight: .semibold))
            .foregroundColor(AppTheme.header)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(Double(flex))
    }

    @ViewBuilder
    private func sessionRow(_ session: Session, isBest: Bool) -> some View {
        let color = isBest ? AppTheme.green : AppTheme.text

        HStack(spacing: 0) {
            Button(action: { sessionsVM.toggleSelection(session.id) }) {
                Image(systemName: sessionsVM.selectedSessionIDs.contains(session.id) ? "checkmark.square.fill" : "square")
                    .foregroundColor(sessionsVM.selectedSessionIDs.contains(session.id) ? AppTheme.accent : AppTheme.muted)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 22, alignment: .leading)
            }
            .buttonStyle(.plain)

            // Charger name + BEST tag
            HStack(spacing: 6) {
                Text(session.name ?? String(localized: "sessions.session.fallback_name"))
                    .font(AppTheme.mono(size: 12))
                    .foregroundColor(color)
                    .lineLimit(1)
                if isBest {
                    Text("sessions.badge.best")
                        .font(AppTheme.mono(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.green.opacity(0.15))
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(2)

            Text(formatDuration(session.duration))
                .font(AppTheme.mono(size: 12))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(session.peakW.map { String(format: "%.1fW", $0) } ?? String(localized: "common.value.unknown"))
                .font(AppTheme.mono(size: 12))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(session.avgW.map { String(format: "%.1fW", $0) } ?? String(localized: "common.value.unknown"))
                .font(AppTheme.mono(size: 12))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(String(format: "%+.1f%%", session.deltaPercent))
                .font(AppTheme.mono(size: 12))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(session.avgTemp.map { String(format: "%.1f°C", $0) } ?? String(localized: "common.value.unknown"))
                .font(AppTheme.mono(size: 12))
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
            Rectangle().fill(AppTheme.border).frame(height: 1)
        }
    }

    @ViewBuilder
    private func ratingTag(_ rating: SessionRating) -> some View {
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
            case .excellent: return (AppTheme.green.opacity(0.15), AppTheme.green)
            case .good: return (AppTheme.yellow.opacity(0.15), AppTheme.yellow)
            case .fair: return (AppTheme.surface2, AppTheme.muted)
            case .poor: return (AppTheme.red.opacity(0.15), AppTheme.red)
            case .unknown: return (AppTheme.surface2, AppTheme.muted)
            }
        }()

        Text(titleKey)
            .font(AppTheme.mono(size: 10, weight: .semibold))
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
