import Foundation

public struct Session: Identifiable, Codable {
    public var id: UUID
    public var startTimestamp: Date
    public var endTimestamp: Date?
    public var samples: [BatterySample]

    public init(id: UUID = UUID(), start: Date = Date(), end: Date? = nil, samples: [BatterySample] = []) {
        self.id = id
        self.startTimestamp = start
        self.endTimestamp = end
        self.samples = samples
    }

    public var duration: TimeInterval {
        let end = endTimestamp ?? Date()
        return end.timeIntervalSince(startTimestamp)
    }

    public var peakW: Double? {
        samples.compactMap { $0.powerW }.max()
    }

    public var avgW: Double? {
        let vals = samples.compactMap { $0.powerW }
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    public var avgTemp: Double? {
        let vals = samples.compactMap { $0.tempC }
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    public var deltaPercent: Double? {
        guard let first = samples.first?.percent, let last = samples.last?.percent else { return nil }
        return last - first
    }

    /// A simple session rating heuristic (0...100).
    /// Higher is better. This combines average temperature, peak power and percent change.
    public var rating: Int {
        var score = 50.0

        if let avgT = avgTemp {
            if avgT <= 40.0 { score += 10 }
            else if avgT <= 50.0 { score += 5 }
            else { score -= 10 }
        }

        if let peak = peakW {
            let p = peak
            if p < 30 { score += 10 }
            else if p < 60 { score += 5 }
            else { score -= 10 }
        }

        if let delta = deltaPercent {
            if delta >= 0 { score += 10 } else { score -= 5 }
        }

        // penalize very short sessions
        if duration < 30 { score -= 5 }
        // clamp
        let clamped = min(max(Int(round(score)), 0), 100)
        return clamped
    }
}
