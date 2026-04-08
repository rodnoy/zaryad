import Domain
import SwiftUI

public struct RecommendationsView: View {
    @EnvironmentObject var recommendationsVM: RecommendationsViewModel

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("recommendations.title")
                .font(AppTheme.mono(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.header)
                .tracking(1)

            if recommendationsVM.recommendations.isEmpty {
                Text("recommendations.empty")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.muted)
            } else {
                ForEach(Array(recommendationsVM.recommendations.prefix(3))) { item in
                    recommendationRow(item)
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func recommendationRow(_ recommendation: Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color(for: recommendation.severity))
                    .frame(width: 8, height: 8)

                Text(recommendation.titleKey)
                    .font(AppTheme.mono(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.text)
            }

            Text(recommendation.messageKey)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.muted)
                .padding(.leading, 16)
        }
        .padding(.vertical, 6)
    }

    private func color(for severity: Recommendation.Severity) -> Color {
        switch severity {
        case .info: return AppTheme.accent
        case .warning: return AppTheme.yellow
        case .critical: return AppTheme.red
        }
    }
}
