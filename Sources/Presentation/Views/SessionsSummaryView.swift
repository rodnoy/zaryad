import SwiftUI
import Domain

extension Presentation {
    public struct SessionsSummaryView: View {
        public var latest: Domain.Session?

        public init(latest: Domain.Session?) { self.latest = latest }

        public var body: some View {
            VStack(alignment: .trailing) {
                Text("Latest session")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let s = latest {
                    Text("Duration: \(Int(s.duration))s")
                    if let avg = s.avgW { Text(String(format: "Avg: %.1f W", avg)) }
                } else {
                    Text("—")
                }
            }
        }
    }
}
