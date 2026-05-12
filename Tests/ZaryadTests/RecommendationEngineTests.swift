import XCTest
@testable import Domain

final class RecommendationEngineTests: XCTestCase {

    // MARK: - All recommendation keys exist in en.lproj

    func testAllRecommendationKeysExistInEnLocalization() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let enPath = root.appendingPathComponent("Resources/en.lproj/Localizable.strings").path
        let enKeys = try parseKeys(from: enPath)

        // Collect all possible recommendation keys by evaluating every rule
        let allKeys = collectAllRecommendationKeys()
        XCTAssertFalse(allKeys.isEmpty, "Should have collected at least one recommendation key")

        for key in allKeys {
            XCTAssertTrue(enKeys.contains(key), "Recommendation key '\(key)' not found in en.lproj/Localizable.strings")
        }
    }

    private func collectAllRecommendationKeys() -> Set<String> {
        // Build contexts that trigger each rule
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        // Context triggering: weak adapter, high temp, low health critical, high cycles critical, near rated, rapid temp
        let heavyContext = RecommendationContext(
            currentSample: BatterySample(
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
            ),
            latestSession: Session(
                start: now.addingTimeInterval(-1800),
                end: now,
                samples: [
                    BatterySample(timestamp: now.addingTimeInterval(-1800), powerW: 15, tempC: 36, isCharging: true, adapterWatts: 70),
                    BatterySample(timestamp: now.addingTimeInterval(-1200), powerW: 20, tempC: 39, isCharging: true, adapterWatts: 70),
                    BatterySample(timestamp: now, powerW: 18, tempC: 40, isCharging: true, adapterWatts: 70)
                ]
            ),
            recentSamples: [
                BatterySample(timestamp: now.addingTimeInterval(-1800), powerW: 15, tempC: 36, isCharging: true, adapterWatts: 70),
                BatterySample(timestamp: now.addingTimeInterval(-1200), powerW: 20, tempC: 39, isCharging: true, adapterWatts: 70),
                BatterySample(timestamp: now, powerW: 18, tempC: 40, isCharging: true, adapterWatts: 70)
            ]
        )

        // Context triggering: low health warning, cycles warning
        let warningContext = RecommendationContext(
            currentSample: BatterySample(
                timestamp: now,
                powerW: 50,
                percent: 50,
                maxMah: 4500,
                designMah: 6000,
                cycleCount: 750,
                tempC: 30,
                isCharging: true,
                pluggedIn: true,
                adapterWatts: 65
            ),
            latestSession: nil,
            recentSamples: []
        )

        // Context triggering: long at 100%
        let stuckSamples = (0..<20).map { i in
            BatterySample(
                timestamp: now.addingTimeInterval(Double(i) * -120),
                powerW: 2,
                percent: 100,
                isCharging: false,
                pluggedIn: true
            )
        }
        let stuckContext = RecommendationContext(
            currentSample: stuckSamples.first,
            latestSession: nil,
            recentSamples: stuckSamples
        )

        // Context triggering: near rated
        let nearRatedSamples = [
            BatterySample(timestamp: now.addingTimeInterval(-600), powerW: 60, isCharging: true, adapterWatts: 65),
            BatterySample(timestamp: now, powerW: 58, isCharging: true, adapterWatts: 65)
        ]
        let nearRatedContext = RecommendationContext(
            currentSample: BatterySample(timestamp: now, powerW: 59, percent: 50, maxMah: 5000, designMah: 5000, cycleCount: 10, tempC: 30, isCharging: true, pluggedIn: true, adapterWatts: 65),
            latestSession: Session(start: now.addingTimeInterval(-600), end: now, samples: nearRatedSamples),
            recentSamples: nearRatedSamples
        )

        // Context triggering: rapid temp increase
        let rapidTempSamples = [
            BatterySample(timestamp: now.addingTimeInterval(-600), powerW: 40, tempC: 28, isCharging: true, adapterWatts: 65),
            BatterySample(timestamp: now.addingTimeInterval(-300), powerW: 40, tempC: 32, isCharging: true, adapterWatts: 65),
            BatterySample(timestamp: now, powerW: 40, tempC: 36, isCharging: true, adapterWatts: 65)
        ]
        let rapidTempContext = RecommendationContext(
            currentSample: BatterySample(timestamp: now, powerW: 40, percent: 50, maxMah: 5000, designMah: 5000, cycleCount: 10, tempC: 36, isCharging: true, pluggedIn: true, adapterWatts: 65),
            latestSession: nil,
            recentSamples: rapidTempSamples
        )

        let engine = RecommendationEngine()
        let contexts = [heavyContext, warningContext, stuckContext, nearRatedContext, rapidTempContext]
        var allKeys = Set<String>()
        for ctx in contexts {
            for rec in engine.evaluate(context: ctx) {
                allKeys.insert(rec.titleKey)
                allKeys.insert(rec.messageKey)
            }
        }
        return allKeys
    }

    private func parseKeys(from path: String) throws -> Set<String> {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let pattern = #"^\s*"([^"]+)"\s*=\s*".*"\s*;\s*$"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        let ns = content as NSString
        var keys = Set<String>()
        for match in regex.matches(in: content, options: [], range: NSRange(location: 0, length: ns.length)) {
            guard match.numberOfRanges > 1 else { continue }
            keys.insert(ns.substring(with: match.range(at: 1)))
        }
        return keys
    }

    // MARK: - Existing tests
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
