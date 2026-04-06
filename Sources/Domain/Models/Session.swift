import Foundation

public enum SessionRating: String, Codable, Sendable {
    case excellent
    case good
    case fair
    case poor
    case unknown
}

public struct Session: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String?
    public var startTimestamp: Date
    public var endTimestamp: Date?
    public var samples: [BatterySample]

    public init(id: UUID = UUID(), name: String? = nil, start: Date = Date(), end: Date? = nil, samples: [BatterySample] = []) {
        self.id = id
        self.name = name
        self.startTimestamp = start
        self.endTimestamp = end
        self.samples = samples
    }

    public var duration: TimeInterval {
        let end = endTimestamp ?? Date()
        return end.timeIntervalSince(startTimestamp)
    }

    public var peakW: Double? {
        let charging = samples.compactMap { $0.powerW }.filter { $0 > 0 }
        return charging.max()
    }

    public var avgW: Double? {
        let charging = samples.compactMap { $0.powerW }.filter { $0 > 0 }
        guard !charging.isEmpty else { return nil }
        return charging.reduce(0, +) / Double(charging.count)
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

    /// Rating based on avgW: >=60 excellent, >=30 good, else fair.
    public var rating: SessionRating {
        guard let avg = avgW else { return .unknown }
        if avg >= 60 { return .excellent }
        if avg >= 30 { return .good }
        if avg > 0 { return .fair }
        return .poor
    }

    /// Numeric rating for sorting (higher is better).
    public var ratingScore: Double {
        return avgW ?? 0
    }
}
