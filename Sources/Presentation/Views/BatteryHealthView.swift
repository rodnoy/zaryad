import Data
import Domain
import SwiftUI

public struct BatteryHealthView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    public let sample: BatterySample?
    public let snapshots: [SDHealthSnapshot]
    public let forecast: BatteryHealthPredictor.Forecast?

    public init(
        sample: BatterySample?,
        snapshots: [SDHealthSnapshot] = [],
        forecast: BatteryHealthPredictor.Forecast? = nil
    ) {
        self.sample = sample
        self.snapshots = snapshots
        self.forecast = forecast
    }

    public var body: some View {
        let palette = themeStore.current.palette
        let headerColor = palette.muted.opacity(0.88)

        VStack(alignment: .leading, spacing: 12) {
            Text("battery.health.title")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(headerColor)
                .tracking(1)

            infoRow(key: String(localized: "battery.health.current"), value: formatHealth())
            infoRow(key: String(localized: "battery.health.row.cycles"), value: formatCurrentCycles())

            if snapshots.count >= 2 {
                chartView()
                    .frame(height: 90)
            }

            if let forecast {
                infoRow(key: String(localized: "battery.health.cycles_to_80"), value: formatCyclesValue(forecast.cyclesTo80))
                infoRow(key: String(localized: "battery.health.cycles_to_70"), value: formatCyclesValue(forecast.cyclesTo70))
                infoRow(key: String(localized: "battery.health.confidence"), value: String(format: "%.2f", forecast.r2))
            } else {
                Text("battery.health.insufficient_data")
                    .font(.system(size: 12))
                    .foregroundColor(palette.muted)
                    .padding(.top, 4)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func infoRow(key: String, value: String) -> some View {
        let palette = themeStore.current.palette

        HStack {
            Text(key)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(palette.muted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(palette.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(palette.surface2)
        )
    }

    @ViewBuilder
    private func chartView() -> some View {
        let palette = themeStore.current.palette

        GeometryReader { geo in
            let sorted = snapshots.sorted { $0.cycleCount < $1.cycleCount }
            let points = sorted.map { (x: Double($0.cycleCount), y: $0.healthPercent) }
            let minX = points.map(\.x).min() ?? 0
            let maxX = points.map(\.x).max() ?? 1
            let minY = min(points.map(\.y).min() ?? 60, 70)
            let maxY = max(points.map(\.y).max() ?? 100, 100)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(palette.surface2)

                Path { path in
                    for point in points {
                        let pointPosition = chartPoint(
                            x: point.x,
                            y: point.y,
                            in: geo.size,
                            minX: minX,
                            maxX: maxX,
                            minY: minY,
                            maxY: maxY
                        )
                        path.addEllipse(in: CGRect(x: pointPosition.x - 2, y: pointPosition.y - 2, width: 4, height: 4))
                    }
                }
                .fill(palette.accent)

                if let forecast {
                    Path { path in
                        let x1 = minX
                        let y1 = forecast.slope * x1 + forecast.intercept
                        let x2 = maxX
                        let y2 = forecast.slope * x2 + forecast.intercept

                        let p1 = chartPoint(x: x1, y: y1, in: geo.size, minX: minX, maxX: maxX, minY: minY, maxY: maxY)
                        let p2 = chartPoint(x: x2, y: y2, in: geo.size, minX: minX, maxX: maxX, minY: minY, maxY: maxY)
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                    .stroke(palette.green, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
            }
        }
    }

    private func chartPoint(
        x: Double,
        y: Double,
        in size: CGSize,
        minX: Double,
        maxX: Double,
        minY: Double,
        maxY: Double
    ) -> CGPoint {
        let xSpan = max(maxX - minX, 1)
        let ySpan = max(maxY - minY, 1)
        let px = ((x - minX) / xSpan) * size.width
        let py = size.height - ((y - minY) / ySpan) * size.height
        return CGPoint(x: px, y: py)
    }

    private func formatHealth() -> String {
        guard let h = sample?.healthPercent else { return String(localized: "common.value.unknown") }
        return "\(Int(h.rounded()))%"
    }

    private func formatCurrentCycles() -> String {
        guard let c = sample?.cycleCount else { return String(localized: "common.value.unknown") }
        return "\(c)"
    }

    private func formatCyclesValue(_ value: Int?) -> String {
        guard let value else { return String(localized: "common.value.unknown") }
        return "\(value)"
    }
}
