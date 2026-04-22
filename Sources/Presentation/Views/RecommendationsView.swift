import Domain
import SwiftUI

public struct RecommendationsView: View {
    @EnvironmentObject var recommendationsVM: RecommendationsViewModel
    @EnvironmentObject private var themeStore: ThemeStore

    public init() {}

    public var body: some View {
        let p = themeStore.current.palette
        let headerColor = p.muted.opacity(0.88)

        VStack(alignment: .leading, spacing: 12) {
            Text("recommendations.title")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(headerColor)
                .tracking(1)

            if recommendationsVM.recommendations.isEmpty {
                Text("recommendations.empty")
                    .font(.system(size: 13))
                    .foregroundColor(p.muted)
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
        let p = themeStore.current.palette

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color(for: recommendation.severity))
                    .frame(width: 8, height: 8)

                Text(LocalizedStringKey(recommendation.titleKey))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(p.text)
            }

            Text(LocalizedStringKey(recommendation.messageKey))
                .font(.system(size: 12))
                .foregroundColor(p.muted)
                .padding(.leading, 16)
        }
        .padding(.vertical, 6)
    }

    private func color(for severity: Recommendation.Severity) -> Color {
        let p = themeStore.current.palette
        switch severity {
        case .info: return p.accent
        case .warning: return p.yellow
        case .critical: return p.red
        }
    }
}
