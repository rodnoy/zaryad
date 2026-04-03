import SwiftUI
import Domain

extension Presentation {
    public struct BatteryCardView: View {
        public var sample: Domain.BatterySample?

        public init(sample: Domain.BatterySample?) {
            self.sample = sample
        }

        public var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
                    .shadow(radius: 2)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Battery")
                            .font(.headline)
                        Spacer()
                        if let p = sample?.percent { Text(String(format: "%.0f%%", p)).font(.title).bold() }
                        else { Text("—").font(.title).bold() }
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("Power: \(sample?.powerW.map { String(format: "%.1f W", $0) } ?? "—")")
                            Text("Voltage: \(sample?.voltageV.map { String(format: "%.2f V", $0) } ?? "—")")
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("State: \(stateText())")
                            Text("Temp: \(sample?.tempC.map { String(format: "%.1f °C", $0) } ?? "—")")
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }

        private func stateText() -> String {
            if let s = sample {
                if s.fullyCharged == true { return "Full" }
                if s.isCharging == true { return "Charging" }
                if s.pluggedIn == true { return "Plugged" }
                return "Discharging"
            }
            return "—"
        }
    }
}
