import SwiftUI
import Domain
import Data


extension Presentation {
    public struct PowerChartView: View {
        public var samples: [Domain.BatterySample]

        public init(samples: [Domain.BatterySample]) {
            self.samples = samples
        }

        public var body: some View {
            GeometryReader { geo in
                ZStack {
                    Color.secondary.opacity(0.12)
                    if samples.isEmpty {
                        Text("No samples")
                            .foregroundColor(.secondary)
                    } else {
                        // Simple polyline rendering of powerW values
                        Path { path in
                            let w = geo.size.width
                            let h = geo.size.height
                            let vals = samples.compactMap { $0.powerW }
                            guard !vals.isEmpty else { return }
                            let minV = vals.min() ?? 0
                            let maxV = vals.max() ?? 1
                            for (i, v) in vals.enumerated() {
                                let x = w * CGFloat(i) / CGFloat(max(1, vals.count - 1))
                                let norm = (v - minV) / (maxV - minV)
                                let y = h - (h * CGFloat(norm))
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Color.accentColor, lineWidth: 2)
                        .padding(8)
                    }
                }
            }
        }
    }
}
