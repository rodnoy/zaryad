import SwiftUI

/// Battery card with percentage, status, animated gradient bar, and capacity info.
public struct BatteryCardView: View {
    public let sample: BatterySample?

    public init(sample: BatterySample?) {
        self.sample = sample
    }

    @State private var shimmerOffset: CGFloat = -1.0

    private var percent: Double { sample?.percent ?? 0 }
    private var statusText: String {
        guard let s = sample else { return "—" }
        if s.fullyCharged == true { return "Fully Charged" }
        if s.isCharging == true { return "Charging" }
        if s.pluggedIn == true { return "Plugged In" }
        return "Discharging"
    }

    private var capacityText: String {
        guard let cur = sample?.currentMah, let max = sample?.maxMah else { return "— mAh" }
        return "\(Int(cur)) / \(Int(max)) mAh"
    }

    private var timeText: String {
        guard let min = sample?.timeRemainingMin, min > 0 else {
            if sample?.fullyCharged == true { return "Full" }
            return "..."
        }
        let h = Int(min) / 60
        let m = Int(min) % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BATTERY")
                .font(AppTheme.mono(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.header)
                .tracking(1)
                .padding(.bottom, 12)

            // Percent + Status row
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(percent))")
                        .font(AppTheme.mono(size: 42, weight: .bold))
                        .foregroundColor(AppTheme.text)
                        .contentTransition(.numericText())
                    Text("%")
                        .font(AppTheme.mono(size: 14))
                        .foregroundColor(AppTheme.muted)
                }
                Spacer()
                Text(statusText)
                    .font(AppTheme.mono(size: 13))
                    .foregroundColor(AppTheme.muted)
            }

            // Battery bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.surface2)
                    .frame(height: 28)

                GeometryReader { geo in
                    let fillWidth = geo.size.width * CGFloat(min(max(percent, 0), 100)) / 100.0
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.batteryGradient(percent: percent))
                        .frame(width: max(fillWidth, 0), height: 28)
                        .overlay(
                            // Shimmer
                            LinearGradient(
                colors: [.clear, AppTheme.text.opacity(0.08), .clear],
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
                    .font(AppTheme.mono(size: 12))
                    .foregroundColor(AppTheme.muted)
                Spacer()
                Text(timeText)
                    .font(AppTheme.mono(size: 12))
                    .foregroundColor(AppTheme.muted)
            }
        }
        .cardStyle()
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.0
            }
        }
    }
}
