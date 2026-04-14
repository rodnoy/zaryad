import Data
import Domain
import SwiftUI

/// A single big-number metric card matching the web dashboard style.
public struct MetricCardView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let label: String
    let value: String
    let unit: String
    let subtitle: String
    var valueColor: Color?

    public init(
        label: String,
        value: String,
        unit: String,
        subtitle: String,
        valueColor: Color? = nil
    ) {
        self.label = label
        self.value = value
        self.unit = unit
        self.subtitle = subtitle
        self.valueColor = valueColor
    }

    public var body: some View {
        let p = themeStore.current.palette
        let headerColor = p.muted.opacity(0.88)

        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(headerColor)
                .tracking(1)
                .padding(.bottom, 8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(valueColor ?? p.text)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(p.muted)
            }

            Text(subtitle)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(p.muted)
                .padding(.top, 6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
