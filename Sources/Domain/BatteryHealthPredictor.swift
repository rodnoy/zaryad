import Foundation

public struct BatteryHealthPredictor: Sendable {
    public struct Observation: Sendable {
        public let timestamp: Date
        public let cycleCount: Int
        public let healthPercent: Double

        public init(timestamp: Date, cycleCount: Int, healthPercent: Double) {
            self.timestamp = timestamp
            self.cycleCount = cycleCount
            self.healthPercent = healthPercent
        }
    }

    public struct Forecast: Sendable {
        public let slope: Double
        public let intercept: Double
        public let r2: Double
        public let points: Int
        public let cyclesTo80: Int?
        public let cyclesTo70: Int?
        public let predictedAt80Date: Date?
        public let predictedAt70Date: Date?

        public init(
            slope: Double,
            intercept: Double,
            r2: Double,
            points: Int,
            cyclesTo80: Int?,
            cyclesTo70: Int?,
            predictedAt80Date: Date?,
            predictedAt70Date: Date?
        ) {
            self.slope = slope
            self.intercept = intercept
            self.r2 = r2
            self.points = points
            self.cyclesTo80 = cyclesTo80
            self.cyclesTo70 = cyclesTo70
            self.predictedAt80Date = predictedAt80Date
            self.predictedAt70Date = predictedAt70Date
        }
    }

    public init() {}

    public func forecast(from observations: [Observation], now: Date = Date()) -> Forecast? {
        let sorted = observations.sorted { $0.cycleCount < $1.cycleCount }
        guard sorted.count >= 3 else { return nil }

        let n = Double(sorted.count)
        let xs = sorted.map { Double($0.cycleCount) }
        let ys = sorted.map { $0.healthPercent }

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXX = xs.reduce(0) { $0 + ($1 * $1) }
        let sumXY = zip(xs, ys).reduce(0) { $0 + ($1.0 * $1.1) }

        let denominator = (n * sumXX) - (sumX * sumX)
        guard denominator != 0 else { return nil }

        let slope = ((n * sumXY) - (sumX * sumY)) / denominator
        let intercept = (sumY - slope * sumX) / n

        let yMean = sumY / n
        let ssTot = ys.reduce(0) { $0 + pow($1 - yMean, 2) }
        let ssRes = zip(xs, ys).reduce(0) { partial, pair in
            let predicted = slope * pair.0 + intercept
            return partial + pow(pair.1 - predicted, 2)
        }
        let r2Raw: Double
        if ssTot == 0 {
            r2Raw = ssRes == 0 ? 1 : 0
        } else {
            r2Raw = 1 - (ssRes / ssTot)
        }
        let r2 = min(1, max(0, r2Raw))

        guard let latest = sorted.last else { return nil }
        let latestCycle = latest.cycleCount

        if slope >= 0 {
            return Forecast(
                slope: slope,
                intercept: intercept,
                r2: r2,
                points: sorted.count,
                cyclesTo80: nil,
                cyclesTo70: nil,
                predictedAt80Date: nil,
                predictedAt70Date: nil
            )
        }

        let cyclesTo80 = cyclesUntil(targetHealth: 80, slope: slope, intercept: intercept, latestCycle: latestCycle)
        let cyclesTo70 = cyclesUntil(targetHealth: 70, slope: slope, intercept: intercept, latestCycle: latestCycle)

        let cyclesPerDay = estimateCyclesPerDay(from: sorted)
        let predictedAt80Date = estimatedDate(now: now, cyclesNeeded: cyclesTo80, cyclesPerDay: cyclesPerDay)
        let predictedAt70Date = estimatedDate(now: now, cyclesNeeded: cyclesTo70, cyclesPerDay: cyclesPerDay)

        return Forecast(
            slope: slope,
            intercept: intercept,
            r2: r2,
            points: sorted.count,
            cyclesTo80: cyclesTo80,
            cyclesTo70: cyclesTo70,
            predictedAt80Date: predictedAt80Date,
            predictedAt70Date: predictedAt70Date
        )
    }

    private func cyclesUntil(targetHealth: Double, slope: Double, intercept: Double, latestCycle: Int) -> Int? {
        guard slope < 0 else { return nil }
        let xAtTarget = (targetHealth - intercept) / slope
        guard xAtTarget.isFinite else { return nil }
        let remaining = Int(ceil(xAtTarget - Double(latestCycle)))
        return min(max(remaining, 0), 20_000)
    }

    private func estimateCyclesPerDay(from observations: [Observation]) -> Double? {
        guard let first = observations.first, let last = observations.last else { return nil }
        let deltaCycles = Double(last.cycleCount - first.cycleCount)
        let deltaDays = last.timestamp.timeIntervalSince(first.timestamp) / 86_400
        guard deltaDays > 0 else { return nil }
        let cyclesPerDay = deltaCycles / deltaDays
        guard cyclesPerDay > 0 else { return nil }
        return cyclesPerDay
    }

    private func estimatedDate(now: Date, cyclesNeeded: Int?, cyclesPerDay: Double?) -> Date? {
        guard let cyclesNeeded, let cyclesPerDay, cyclesPerDay > 0 else { return nil }
        let days = Double(cyclesNeeded) / cyclesPerDay
        guard days.isFinite, days >= 0 else { return nil }
        return now.addingTimeInterval(days * 86_400)
    }
}
