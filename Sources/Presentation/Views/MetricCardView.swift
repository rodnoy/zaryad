import SwiftUI

/// A single big-number metric card matching the web dashboard style.
public struct MetricCardView: View {
    let label: String
    let value: String
    let unit: String
    let subtitle: String
    var valueColor: Color = AppTheme.text
    var topAccent: Color? = nil

    public init(
        label: String,
        value: String,
        unit: String,
        subtitle: String,
        valueColor: Color = AppTheme.text,
        topAccent: Color? = nil
    ) {
        self.label = label
        self.value = value
        self.unit = unit
        self.subtitle = subtitle
        self.valueColor = valueColor
        self.topAccent = topAccent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(AppTheme.mono(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.header)
                .tracking(1)
                .padding(.bottom, 8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(AppTheme.mono(size: 32, weight: .bold))
                    .foregroundColor(valueColor)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(AppTheme.mono(size: 14))
                    .foregroundColor(AppTheme.muted)
            }

            Text(subtitle)
                .font(AppTheme.mono(size: 12))
                .foregroundColor(AppTheme.muted)
                .padding(.top, 6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(topAccent: topAccent)
    }
}
