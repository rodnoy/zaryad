import Foundation

public struct Recommendation: Identifiable, Sendable, Equatable {
    public enum Severity: Int, Sendable, Comparable {
        case info = 0
        case warning = 1
        case critical = 2

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public let id: UUID
    public let titleKey: String
    public let messageKey: String
    public let severity: Severity
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        titleKey: String,
        messageKey: String,
        severity: Severity,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.titleKey = titleKey
        self.messageKey = messageKey
        self.severity = severity
        self.createdAt = createdAt
    }
}

public struct RecommendationContext: Sendable {
    public let currentSample: BatterySample?
    public let latestSession: Session?
    public let recentSamples: [BatterySample]
    public let healthSnapshots: [BatteryHealthPredictor.Observation]
    public let healthForecast: BatteryHealthPredictor.Forecast?

    public init(
        currentSample: BatterySample?,
        latestSession: Session?,
        recentSamples: [BatterySample],
        healthSnapshots: [BatteryHealthPredictor.Observation] = [],
        healthForecast: BatteryHealthPredictor.Forecast? = nil
    ) {
        self.currentSample = currentSample
        self.latestSession = latestSession
        self.recentSamples = recentSamples
        self.healthSnapshots = healthSnapshots
        self.healthForecast = healthForecast
    }
}

public protocol RecommendationRule: Sendable {
    func evaluate(context: RecommendationContext) -> Recommendation?
}

public struct RecommendationEngine: Sendable {
    private let rules: [any RecommendationRule]

    public init(rules: [any RecommendationRule] = RecommendationEngine.defaultRules) {
        self.rules = rules
    }

    public func evaluate(context: RecommendationContext) -> [Recommendation] {
        let output = rules.compactMap { $0.evaluate(context: context) }
        return output.sorted {
            if $0.severity == $1.severity {
                return $0.createdAt > $1.createdAt
            }
            return $0.severity > $1.severity
        }
    }

    public static let defaultRules: [any RecommendationRule] = [
        WeakAdapterRule(),
        HighTemperatureWhileChargingRule(),
        LowBatteryHealthRule(),
        HighCycleCountRule(),
        LongAtHundredWhilePluggedRule(),
        NearRatedPowerRule(),
        RapidTemperatureIncreaseRule()
    ]
}

private struct WeakAdapterRule: RecommendationRule {
    func evaluate(context: RecommendationContext) -> Recommendation? {
        guard let adapter = context.currentSample?.adapterWatts, adapter > 0 else { return nil }
        let avgPower = context.latestSession?.avgChargingPowerW
            ?? averagePositivePower(in: context.recentSamples)
        guard let avgPower else { return nil }
        guard avgPower < adapter * 0.5 else { return nil }
        return Recommendation(
            titleKey: "recommendation.weak_adapter.title",
            messageKey: "recommendation.weak_adapter.message",
            severity: .warning
        )
    }
}

private struct HighTemperatureWhileChargingRule: RecommendationRule {
    func evaluate(context: RecommendationContext) -> Recommendation? {
        guard context.currentSample?.isCharging == true else { return nil }
        let avgTemp = context.latestSession?.avgTempC ?? averageTemperature(in: context.recentSamples)
        guard let avgTemp, avgTemp > 38 else { return nil }
        return Recommendation(
            titleKey: "recommendation.high_temp.title",
            messageKey: "recommendation.high_temp.message",
            severity: .warning
        )
    }
}

private struct LowBatteryHealthRule: RecommendationRule {
    func evaluate(context: RecommendationContext) -> Recommendation? {
        guard let health = context.currentSample?.healthPercent else { return nil }
        if health < 70 {
            return Recommendation(
                titleKey: "recommendation.low_health_critical.title",
                messageKey: "recommendation.low_health_critical.message",
                severity: .critical
            )
        }
        if health < 80 {
            return Recommendation(
                titleKey: "recommendation.low_health_warning.title",
                messageKey: "recommendation.low_health_warning.message",
                severity: .warning
            )
        }
        return nil
    }
}

private struct HighCycleCountRule: RecommendationRule {
    func evaluate(context: RecommendationContext) -> Recommendation? {
        guard let cycles = context.currentSample?.cycleCount else { return nil }
        if cycles > 1000 {
            return Recommendation(
                titleKey: "recommendation.cycles_critical.title",
                messageKey: "recommendation.cycles_critical.message",
                severity: .critical
            )
        }
        if cycles > 700 {
            return Recommendation(
                titleKey: "recommendation.cycles_warning.title",
                messageKey: "recommendation.cycles_warning.message",
                severity: .warning
            )
        }
        return nil
    }
}

private struct LongAtHundredWhilePluggedRule: RecommendationRule {
    func evaluate(context: RecommendationContext) -> Recommendation? {
        let window = context.recentSamples.suffix(20)
        guard window.count >= 10 else { return nil }
        let stuck = window.allSatisfy {
            ($0.percent ?? 0) >= 99.5 && $0.pluggedIn == true
        }
        guard stuck else { return nil }
        return Recommendation(
            titleKey: "recommendation.long_100.title",
            messageKey: "recommendation.long_100.message",
            severity: .info
        )
    }
}

private struct NearRatedPowerRule: RecommendationRule {
    func evaluate(context: RecommendationContext) -> Recommendation? {
        guard let sample = context.currentSample,
              sample.isCharging == true,
              let adapter = sample.adapterWatts,
              adapter > 0
        else {
            return nil
        }

        let avgPower = context.latestSession?.avgChargingPowerW
            ?? averagePositivePower(in: context.recentSamples)
        guard let avgPower else { return nil }
        guard avgPower >= adapter * 0.85 else { return nil }
        return Recommendation(
            titleKey: "recommendation.near_rated.title",
            messageKey: "recommendation.near_rated.message",
            severity: .info
        )
    }
}

private struct RapidTemperatureIncreaseRule: RecommendationRule {
    func evaluate(context: RecommendationContext) -> Recommendation? {
        let charging = context.recentSamples.filter { $0.isCharging == true }
        guard charging.count >= 3 else { return nil }
        guard let first = charging.first, let last = charging.last,
              let firstTemp = first.tempC, let lastTemp = last.tempC
        else {
            return nil
        }

        let deltaTemp = lastTemp - firstTemp
        let deltaMinutes = last.timestamp.timeIntervalSince(first.timestamp) / 60
        guard deltaMinutes > 0 else { return nil }
        let risePerMinute = deltaTemp / deltaMinutes
        guard deltaTemp >= 4, risePerMinute > 0.2 else { return nil }
        return Recommendation(
            titleKey: "recommendation.rapid_temp.title",
            messageKey: "recommendation.rapid_temp.message",
            severity: .warning
        )
    }
}

private func averagePositivePower(in samples: [BatterySample]) -> Double? {
    let values = samples.compactMap(\.powerW).filter { $0 > 0 }
    guard !values.isEmpty else { return nil }
    return values.reduce(0, +) / Double(values.count)
}

private func averageTemperature(in samples: [BatterySample]) -> Double? {
    let values = samples.compactMap(\.tempC)
    guard !values.isEmpty else { return nil }
    return values.reduce(0, +) / Double(values.count)
}
