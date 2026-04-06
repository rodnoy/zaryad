import Data
import Domain
import SwiftUI

/// Canvas-based power chart matching the web dashboard.
/// Shows last ~150 samples with green area above zero (charging) and yellow below (discharging).
public struct PowerChartView: View {
    public let samples: [BatterySample]
    public let showTemperatureOverlay: Bool
    public let onToggleTemperatureOverlay: (() -> Void)?
    private let maxPoints = 150

    public init(
        samples: [BatterySample],
        showTemperatureOverlay: Bool = false,
        onToggleTemperatureOverlay: (() -> Void)? = nil
    ) {
        self.samples = samples
        self.showTemperatureOverlay = showTemperatureOverlay
        self.onToggleTemperatureOverlay = onToggleTemperatureOverlay
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("power.chart.title")
                    .font(AppTheme.mono(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.header)
                    .tracking(0.5)

                Spacer()

                HStack(spacing: 16) {
                    if let onToggleTemperatureOverlay {
                        Button(action: onToggleTemperatureOverlay) {
                            HStack(spacing: 6) {
                                Image(systemName: showTemperatureOverlay ? "checkmark.circle.fill" : "circle")
                                Text("chart.show_temperature")
                            }
                            .font(AppTheme.mono(size: 11, weight: .semibold))
                            .foregroundColor(showTemperatureOverlay ? AppTheme.accent : AppTheme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                    legendItem(color: AppTheme.green, label: "power.chart.legend.charging")
                    legendItem(color: AppTheme.yellow, label: "power.chart.legend.discharge")
                    if showTemperatureOverlay {
                        legendItem(color: AppTheme.accent.opacity(0.8), label: "power.chart.legend.temperature")
                    }
                }
            }
            .padding(.bottom, 16)

            // Chart canvas
            Canvas { context, size in
                drawChart(context: context, size: size)
            }
            .frame(height: 180)
        }
        .cardStyle()
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(AppTheme.mono(size: 11))
                .foregroundColor(AppTheme.header)
        }
    }

    // MARK: - Chart Drawing

    private func drawChart(context: GraphicsContext, size: CGSize) {
        let data = samples.suffix(maxPoints).compactMap { $0.powerW }
        guard data.count >= 2 else { return }

        let tempSeries = showTemperatureOverlay
            ? samples.suffix(maxPoints).map { $0.tempC }
            : []

        let pad = EdgeInsets(top: 10, leading: 44, bottom: 30, trailing: 10)
        let cW = size.width - pad.leading - pad.trailing
        let cH = size.height - pad.top - pad.bottom

        let maxP = max(data.map { abs($0) }.max() ?? 5, 5)
        let minY = -maxP * 1.15
        let maxY = maxP * 1.15

        let offset = max(0, maxPoints - data.count)

        func toX(_ i: Int) -> CGFloat {
            pad.leading + (CGFloat(i + offset) / CGFloat(maxPoints - 1)) * cW
        }
        func toY(_ v: Double) -> CGFloat {
            pad.top + cH - CGFloat((v - minY) / (maxY - minY)) * cH
        }

        let zeroY = toY(0)

        let tempValues = tempSeries.compactMap { $0 }
        let minTemp = tempValues.min() ?? 0
        let maxTemp = tempValues.max() ?? 0
        let tempRange = max(0.1, maxTemp - minTemp)
        func tempToY(_ v: Double) -> CGFloat {
            pad.top + cH - CGFloat((v - minTemp) / tempRange) * cH
        }

        // Grid lines
        for g in 1...3 {
            let yG = pad.top + (CGFloat(g) / 4.0) * cH
            var gridPath = Path()
            gridPath.move(to: CGPoint(x: pad.leading, y: yG))
            gridPath.addLine(to: CGPoint(x: pad.leading + cW, y: yG))
            context.stroke(gridPath, with: .color(AppTheme.border.opacity(0.06)), lineWidth: 1)
        }

        // Dashed zero line
        var zeroPath = Path()
        zeroPath.move(to: CGPoint(x: pad.leading, y: zeroY))
        zeroPath.addLine(to: CGPoint(x: pad.leading + cW, y: zeroY))
        context.stroke(
            zeroPath,
            with: .color(AppTheme.border.opacity(0.12)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )

        // Y-axis labels
        let labelFont = Font.system(size: 10, weight: .regular, design: .monospaced)

        context.draw(
            Text("\(Int(maxP))W").font(labelFont).foregroundColor(AppTheme.muted),
            at: CGPoint(x: pad.leading - 6, y: pad.top + 4),
            anchor: .trailing
        )
        context.draw(
            Text("0").font(labelFont).foregroundColor(AppTheme.muted),
            at: CGPoint(x: pad.leading - 6, y: zeroY + 4),
            anchor: .trailing
        )
        context.draw(
            Text("-\(Int(maxP))W").font(labelFont).foregroundColor(AppTheme.muted),
            at: CGPoint(x: pad.leading - 6, y: size.height - pad.bottom - 4),
            anchor: .trailing
        )

        if showTemperatureOverlay, !tempValues.isEmpty {
            context.draw(
                Text("\(Int(maxTemp))°C").font(labelFont).foregroundColor(AppTheme.accent.opacity(0.8)),
                at: CGPoint(x: size.width - pad.trailing + 4, y: pad.top + 4),
                anchor: .leading
            )
            context.draw(
                Text("\(Int(minTemp))°C").font(labelFont).foregroundColor(AppTheme.accent.opacity(0.8)),
                at: CGPoint(x: size.width - pad.trailing + 4, y: size.height - pad.bottom - 4),
                anchor: .leading
            )

            var tempPath = Path()
            var didMove = false
            var lastPoint: CGPoint?
            for (index, maybeTemp) in tempSeries.enumerated() {
                guard let temp = maybeTemp else { continue }
                let point = CGPoint(x: toX(index), y: tempToY(temp))
                if !didMove {
                    tempPath.move(to: point)
                    didMove = true
                } else {
                    tempPath.addLine(to: point)
                }
                lastPoint = point
            }

            if didMove {
                context.stroke(tempPath, with: .color(AppTheme.accent.opacity(0.8)), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
                if let marker = lastPoint {
                    context.fill(Path(ellipseIn: CGRect(x: marker.x - 2, y: marker.y - 2, width: 4, height: 4)), with: .color(AppTheme.accent.opacity(0.8)))
                }
            }
        }

        // Fill area above zero (charging) — green gradient
        var upPath = Path()
        upPath.move(to: CGPoint(x: toX(0), y: zeroY))
        for (i, v) in data.enumerated() {
            upPath.addLine(to: CGPoint(x: toX(i), y: toY(max(0, v))))
        }
        upPath.addLine(to: CGPoint(x: toX(data.count - 1), y: zeroY))
        upPath.closeSubpath()

        let greenGradient = Gradient(colors: [
            AppTheme.green.opacity(0.3),
            AppTheme.green.opacity(0.02)
        ])
        context.fill(upPath, with: .linearGradient(
            greenGradient,
            startPoint: CGPoint(x: 0, y: pad.top),
            endPoint: CGPoint(x: 0, y: zeroY)
        ))

        // Fill area below zero (discharging) — yellow gradient
        var downPath = Path()
        downPath.move(to: CGPoint(x: toX(0), y: zeroY))
        for (i, v) in data.enumerated() {
            downPath.addLine(to: CGPoint(x: toX(i), y: toY(min(0, v))))
        }
        downPath.addLine(to: CGPoint(x: toX(data.count - 1), y: zeroY))
        downPath.closeSubpath()

        let yellowGradient = Gradient(colors: [
            AppTheme.yellow.opacity(0.02),
            AppTheme.yellow.opacity(0.25)
        ])
        context.fill(downPath, with: .linearGradient(
            yellowGradient,
            startPoint: CGPoint(x: 0, y: zeroY),
            endPoint: CGPoint(x: 0, y: size.height - pad.bottom)
        ))

        // Power line
        var linePath = Path()
        for (i, v) in data.enumerated() {
            let pt = CGPoint(x: toX(i), y: toY(v))
            if i == 0 { linePath.move(to: pt) }
            else { linePath.addLine(to: pt) }
        }
        let lineColor = (data.last ?? 0) >= 0 ? AppTheme.green : AppTheme.yellow
        context.stroke(linePath, with: .color(lineColor), lineWidth: 1.5)
    }
}
