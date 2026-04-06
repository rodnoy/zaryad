import Domain
import SwiftUI

#if canImport(Charts)
import Charts
#endif

public struct SessionBarChartView: View {
    public let sessions: [Session]

    public init(sessions: [Session]) {
        self.sessions = sessions
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("sessions.chart.title")
                .font(AppTheme.mono(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.header)
                .tracking(0.5)

            if chartRows.isEmpty {
                Text("sessions.chart.empty")
                    .font(AppTheme.mono(size: 11))
                    .foregroundColor(AppTheme.muted)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
            } else {
                chartContent
                    .frame(height: 220)
            }
        }
    }

    private var chartRows: [ChartRow] {
        sessions.map { session in
            ChartRow(
                sessionID: session.id,
                label: shortLabel(for: session),
                fullName: session.name ?? String(localized: "sessions.session.fallback_name"),
                avgW: session.avgChargingPowerW,
                peakW: session.peakPowerW
            )
        }
    }

    private func shortLabel(for session: Session) -> String {
        if let name = session.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: session.startTimestamp)
    }

    #if canImport(Charts)
    @ViewBuilder
    private var chartContent: some View {
        Chart {
            ForEach(chartRows) { row in
                if let avgW = row.avgW {
                    BarMark(
                        x: .value("Session", row.label),
                        y: .value("Power", avgW),
                        width: 10
                    )
                    .position(by: .value("Metric", "avg"))
                    .foregroundStyle(AppTheme.accent)
                    .annotation(position: .overlay, alignment: .top) {
                        EmptyView()
                            .help(tooltip(for: row))
                    }
                }

                if let peakW = row.peakW {
                    BarMark(
                        x: .value("Session", row.label),
                        y: .value("Power", peakW),
                        width: 10
                    )
                    .position(by: .value("Metric", "peak"))
                    .foregroundStyle(AppTheme.accent.opacity(0.35))
                    .annotation(position: .overlay, alignment: .top) {
                        EmptyView()
                            .help(tooltip(for: row))
                    }
                }
            }
        }
        .chartLegend(position: .top, alignment: .trailing) {
            HStack(spacing: 12) {
                legendDot(color: AppTheme.accent, text: "sessions.chart.legend.avg")
                legendDot(color: AppTheme.accent.opacity(0.35), text: "sessions.chart.legend.peak")
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    #else
    private var chartContent: some View {
        Canvas { context, size in
            let rows = chartRows
            let values = rows.flatMap { [$0.avgW ?? 0, $0.peakW ?? 0] }
            let maxValue = max(values.max() ?? 1, 1)
            let topPad: CGFloat = 16
            let bottomPad: CGFloat = 24
            let chartHeight = size.height - topPad - bottomPad
            let groupWidth = size.width / CGFloat(max(rows.count, 1))

            for (index, row) in rows.enumerated() {
                let centerX = groupWidth * (CGFloat(index) + 0.5)
                let barWidth = min(12, groupWidth * 0.25)

                if let avg = row.avgW {
                    let h = CGFloat(avg / maxValue) * chartHeight
                    let rect = CGRect(x: centerX - barWidth - 2, y: topPad + (chartHeight - h), width: barWidth, height: h)
                    context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(AppTheme.accent))
                }

                if let peak = row.peakW {
                    let h = CGFloat(peak / maxValue) * chartHeight
                    let rect = CGRect(x: centerX + 2, y: topPad + (chartHeight - h), width: barWidth, height: h)
                    context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(AppTheme.accent.opacity(0.35)))
                }
            }
        }
    }
    #endif

    private func tooltip(for row: ChartRow) -> String {
        let avg = row.avgW.map { String(format: "%.1fW", $0) } ?? String(localized: "common.value.unknown")
        let peak = row.peakW.map { String(format: "%.1fW", $0) } ?? String(localized: "common.value.unknown")
        return "\(row.fullName)\n\(String(localized: "sessions.chart.tooltip.avg")): \(avg)\n\(String(localized: "sessions.chart.tooltip.peak")): \(peak)"
    }

    @ViewBuilder
    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
                .font(AppTheme.mono(size: 10))
                .foregroundColor(AppTheme.header)
        }
    }
}

private struct ChartRow: Identifiable {
    let sessionID: UUID
    let label: String
    let fullName: String
    let avgW: Double?
    let peakW: Double?

    var id: UUID { sessionID }
}
