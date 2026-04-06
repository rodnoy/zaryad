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

    /// Fallback design capacity used when no battery capacity was captured in samples.
    public static let defaultDesignCapacityMah: Double = 6000

    /// Session duration in seconds.
    public var durationSeconds: Double {
        max(0, duration)
    }

    /// Average battery max capacity across all samples where it is available.
    public var averageBatteryCapacityMah: Double? {
        let capacities = samples.compactMap(\.maxMah)
        guard !capacities.isEmpty else { return nil }
        return capacities.reduce(0, +) / Double(capacities.count)
    }

    /// Adapter watts from the first sample where the value is available.
    public var adapterWatts: Double? {
        samples.compactMap(\.adapterWatts).first
    }

    /// Delta in battery percentage points during the session.
    public var deltaPercent: Double {
        guard let first = samples.first?.percent, let last = samples.last?.percent else { return 0 }
        return last - first
    }

    /// Percentage points per hour. Nil for very short sessions and no-change sessions.
    public var percentPerHour: Double? {
        guard durationSeconds >= 30 else { return nil }
        let delta = deltaPercent
        guard delta != 0 else { return nil }
        let hours = durationSeconds / 3600
        guard hours > 0 else { return nil }
        return delta / hours
    }

    /// Delta in mAh estimated from percent delta and known battery capacity.
    public var deltaMah: Double? {
        guard !samples.isEmpty else { return nil }

        let capacityMah: Double? =
            averageBatteryCapacityMah
            ?? samples.first?.maxMah
            ?? samples.compactMap(\.maxMah).first
            ?? Session.defaultDesignCapacityMah

        guard let capacityMah else { return nil }
        return (deltaPercent / 100.0) * capacityMah
    }

    /// mAh per hour estimated from deltaMah and session duration.
    public var mahPerHour: Double? {
        guard let deltaMah else { return nil }
        guard durationSeconds >= 30 else { return nil }
        let hours = durationSeconds / 3600
        guard hours > 0 else { return nil }
        return deltaMah / hours
    }

    /// Average charging power (positive values only).
    public var avgChargingPowerW: Double? {
        let charging = samples.compactMap(\.powerW).filter { $0 > 0 }
        guard !charging.isEmpty else { return nil }
        return charging.reduce(0, +) / Double(charging.count)
    }

    /// Peak power by absolute value (covers both charging and discharging sessions).
    public var peakPowerW: Double? {
        samples.compactMap(\.powerW).map { abs($0) }.max()
    }

    /// Charging efficiency relative to adapter wattage.
    public var efficiencyPercent: Double? {
        guard let avgChargingPowerW else { return nil }
        guard let adapter = adapterWatts, adapter > 0 else { return nil }
        return (avgChargingPowerW / adapter) * 100.0
    }

    /// Average battery temperature across the session.
    public var avgTempC: Double? {
        let values = samples.compactMap(\.tempC)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    public var peakW: Double? {
        let charging = samples.compactMap(\.powerW).filter { $0 > 0 }
        return charging.max()
    }

    public var avgW: Double? {
        avgChargingPowerW
    }

    public var avgTemp: Double? {
        avgTempC
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
