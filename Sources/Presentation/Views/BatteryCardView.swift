import Data
import Domain
import SwiftUI

/// Battery card with percentage, status, animated gradient bar, and capacity info.
public struct BatteryCardView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    public let sample: BatterySample?

    public init(sample: BatterySample?) {
        self.sample = sample
    }

    @State private var shimmerOffset: CGFloat = -1.0

    private var percent: Double { sample?.percent ?? 0 }
    private var statusText: String {
        guard let s = sample else { return String(localized: "common.value.unknown") }
        if s.fullyCharged == true { return String(localized: "battery.card.status.fully_charged") }
        if s.isCharging == true { return String(localized: "battery.card.status.charging") }
        if s.pluggedIn == true { return String(localized: "battery.card.status.plugged_in") }
        return String(localized: "battery.card.status.discharging")
    }

    private var capacityText: String {
        guard let cur = sample?.currentMah, let max = sample?.maxMah else {
            return String(localized: "battery.card.capacity.unknown")
        }
        return String(format: String(localized: "battery.card.capacity.format"), Int(cur), Int(max))
    }

    private var timeText: String {
        guard let min = sample?.timeRemainingMin, min > 0 else {
            if sample?.fullyCharged == true { return String(localized: "battery.card.time.full") }
            return String(localized: "battery.card.time.pending")
        }
        let h = Int(min) / 60
        let m = Int(min) % 60
        if h > 0 {
            return String(format: String(localized: "battery.card.time.hours_minutes.format"), h, m)
        }
        return String(format: String(localized: "battery.card.time.minutes.format"), m)
    }

    private var batteryGradient: LinearGradient {
        let p = themeStore.current.palette
        if percent <= 20 {
            return LinearGradient(colors: [p.red, p.yellow], startPoint: .leading, endPoint: .trailing)
        }
        if percent <= 40 {
            return LinearGradient(colors: [p.yellow, p.accent], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(colors: [p.green, p.accent], startPoint: .leading, endPoint: .trailing)
    }

    public var body: some View {
        let p = themeStore.current.palette
        let headerColor = p.muted.opacity(0.88)

        VStack(alignment: .leading, spacing: 0) {
            Text("battery.card.title")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(headerColor)
                .tracking(1)
                .padding(.bottom, 12)

            // Percent + Status row
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(percent))")
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundColor(p.text)
                        .contentTransition(.numericText())
                    Text("%")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(p.muted)
                }
                Spacer()
                Text(statusText)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(p.muted)
            }

            // Battery bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(p.surface2)
                    .frame(height: 28)

                GeometryReader { geo in
                    let fillWidth = geo.size.width * CGFloat(min(max(percent, 0), 100)) / 100.0
                    RoundedRectangle(cornerRadius: 8)
                        .fill(batteryGradient)
                        .frame(width: max(fillWidth, 0), height: 28)
                        .overlay(
                            // Shimmer
                            LinearGradient(
                                colors: [.clear, p.text.opacity(0.08), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: fillWidth * 0.4)
                            .offset(x: shimmerOffset * fillWidth)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .animation(.easeInOut(duration: 1.0), value: percent)
                }
                .frame(height: 28)
            }
            .padding(.vertical, 12)

            // Bottom stats
            HStack {
                Text(capacityText)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(p.muted)
                Spacer()
                Text(timeText)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(p.muted)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("battery.card.title")
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.0
            }
        }
    }
}
