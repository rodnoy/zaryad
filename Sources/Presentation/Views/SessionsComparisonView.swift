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
                    Text("CHARGER COMPARISON")
                        .font(AppTheme.mono(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.muted)
                        .tracking(1)
                    Text("Plug charger → record session → switch → repeat")
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
                            Text("Stop")
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
                            sessionName = "Charger \(sessionsVM.sessions.count + 1)"
                            showNameInput = true
                        }) {
                            Text("Record Session")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppTheme.accent)
                                )
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                    }

                    if !sessionsVM.sessions.isEmpty {
                        Button(action: {
                            Task { await sessionsVM.deleteAll() }
                        }) {
                            Text("Clear")
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
                sessionsTable
            }
        }
        .cardStyle()
        .alert("Session Name", isPresented: $showNameInput) {
            TextField("Charger name", text: $sessionName)
            Button("Start") {
                Task { await realtime.startSession(name: sessionName) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for this charging session")
        }
    }

    // MARK: - Recording badge

    private var recordingBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.green)
                .frame(width: 8, height: 8)
            Text("Recording")
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
            Text("No recorded sessions.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.muted)
            Text("Plug in a charger and press \"Record Session\".")
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
                tableHeader("Charger", flex: 2)
                tableHeader("Duration", flex: 1)
                tableHeader("Peak W", flex: 1)
                tableHeader("Avg W", flex: 1)
                tableHeader("+% Charge", flex: 1)
                tableHeader("Avg Temp", flex: 1)
                tableHeader("Rating", flex: 1)
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
        Text(title.uppercased())
            .font(AppTheme.mono(size: 11, weight: .semibold))
            .foregroundColor(AppTheme.muted)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(Double(flex))
    }

    @ViewBuilder
    private func sessionRow(_ session: Session, isBest: Bool) -> some View {
        let color = isBest ? AppTheme.green : AppTheme.text

        HStack(spacing: 0) {
            // Charger name + BEST tag
            HStack(spacing: 6) {
                Text(session.name ?? "Session")
                    .font(AppTheme.mono(size: 12))
                    .foregroundColor(color)
                    .lineLimit(1)
                if isBest {
                    Text("BEST")
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

            Text(session.peakW.map { String(format: "%.1fW", $0) } ?? "—")
                .font(AppTheme.mono(size: 12))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(session.avgW.map { String(format: "%.1fW", $0) } ?? "—")
                .font(AppTheme.mono(size: 12))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(session.deltaPercent.map { String(format: "%+.1f%%", $0) } ?? "—")
                .font(AppTheme.mono(size: 12))
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(session.avgTemp.map { String(format: "%.1f°C", $0) } ?? "—")
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
            Rectangle().fill(.white.opacity(0.04)).frame(height: 1)
        }
    }

    @ViewBuilder
    private func ratingTag(_ rating: String) -> some View {
        let (bgColor, fgColor): (Color, Color) = {
            switch rating {
            case "Excellent": return (AppTheme.green.opacity(0.15), AppTheme.green)
            case "Good": return (AppTheme.yellow.opacity(0.15), AppTheme.yellow)
            default: return (AppTheme.surface2, AppTheme.muted)
            }
        }()

        Text(rating)
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
            return "\(s / 60)m \(s % 60)s"
        }
        return "\(s)s"
    }
}
