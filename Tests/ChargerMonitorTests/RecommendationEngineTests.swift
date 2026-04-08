import XCTest
@testable import Domain

final class RecommendationEngineTests: XCTestCase {
    func testEngineTriggersCriticalAndWarningRules() {
        let engine = RecommendationEngine()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let current = BatterySample(
            timestamp: now,
            powerW: 18,
            percent: 99,
            maxMah: 3800,
            designMah: 6000,
            cycleCount: 1050,
            tempC: 40,
            isCharging: true,
            pluggedIn: true,
            adapterWatts: 70
        )

        let session = Session(
            start: now.addingTimeInterval(-1800),
            end: now,
            samples: [
                BatterySample(timestamp: now.addingTimeInterval(-1800), powerW: 15, tempC: 36, isCharging: true, adapterWatts: 70),
                BatterySample(timestamp: now.addingTimeInterval(-1200), powerW: 20, tempC: 39, isCharging: true, adapterWatts: 70),
                BatterySample(timestamp: now, powerW: 18, tempC: 40, isCharging: true, adapterWatts: 70)
            ]
        )

        let context = RecommendationContext(
            currentSample: current,
            latestSession: session,
            recentSamples: session.samples
        )

        let recommendations = engine.evaluate(context: context)
        let keys = Set(recommendations.map(\.titleKey))

        XCTAssertTrue(keys.contains("recommendation.low_health_critical.title"))
        XCTAssertTrue(keys.contains("recommendation.cycles_critical.title"))
        XCTAssertTrue(keys.contains("recommendation.high_temp.title"))
        XCTAssertTrue(keys.contains("recommendation.weak_adapter.title"))
    }

    func testEngineTriggersNearRatedInfoRule() {
        let engine = RecommendationEngine()
        let now = Date()
        let samples = [
            BatterySample(timestamp: now.addingTimeInterval(-600), powerW: 60, isCharging: true, adapterWatts: 65),
            BatterySample(timestamp: now, powerW: 58, isCharging: true, adapterWatts: 65)
        ]
        let session = Session(start: now.addingTimeInterval(-600), end: now, samples: samples)
        let current = BatterySample(timestamp: now, powerW: 59, isCharging: true, adapterWatts: 65)

        let context = RecommendationContext(
            currentSample: current,
            latestSession: session,
            recentSamples: samples
        )

        let recommendations = engine.evaluate(context: context)
        XCTAssertTrue(recommendations.contains { $0.titleKey == "recommendation.near_rated.title" })
    }
}
