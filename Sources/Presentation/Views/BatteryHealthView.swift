import SwiftUI

/// Battery health info card with 2-column grid (matching web "Состояние батареи" section).
public struct BatteryHealthView: View {
    public let sample: BatterySample?

    public init(sample: BatterySample?) {
        self.sample = sample
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BATTERY HEALTH")
                .font(AppTheme.mono(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.header)
                .tracking(1)
                .padding(.bottom, 12)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                infoRow(key: "Health", value: formatHealth())
                infoRow(key: "Cycles", value: formatCycles())
                infoRow(key: "Max Capacity", value: formatMaxCap())
                infoRow(key: "Design Capacity", value: formatDesignCap())
                infoRow(key: "Adapter", value: formatAdapter())
                infoRow(key: "Plugged In", value: formatPlugged())
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func infoRow(key: String, value: String) -> some View {
        HStack {
            Text(key)
                .font(AppTheme.mono(size: 12))
                .foregroundColor(AppTheme.muted)
            Spacer()
            Text(value)
                .font(AppTheme.mono(size: 13, weight: .medium))
                .foregroundColor(AppTheme.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.surface2)
        )
    }

    // MARK: - Formatters

    private func formatHealth() -> String {
        guard let h = sample?.healthPercent else { return "—" }
        return "\(Int(h))%"
    }

    private func formatCycles() -> String {
        guard let c = sample?.cycleCount else { return "—" }
        return "\(c)"
    }

    private func formatMaxCap() -> String {
        guard let m = sample?.maxMah else { return "—" }
        return "\(Int(m)) mAh"
    }

    private func formatDesignCap() -> String {
        guard let d = sample?.designMah else { return "—" }
        return "\(Int(d)) mAh"
    }

    private func formatAdapter() -> String {
        guard let w = sample?.adapterWatts else { return "—" }
        return "\(Int(w))W"
    }

    private func formatPlugged() -> String {
        guard let p = sample?.pluggedIn else { return "—" }
        return p ? "Yes" : "No"
    }
}
