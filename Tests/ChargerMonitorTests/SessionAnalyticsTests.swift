import XCTest
@testable import Domain

final class SessionAnalyticsTests: XCTestCase {
    func testDerivedMetricsForChargingSession() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(3600)

        let samples = [
            BatterySample(
                timestamp: start,
                powerW: 30,
                percent: 40,
                maxMah: 5000,
                cycleCount: 120,
                tempC: 31,
                adapterWatts: 70
            ),
            BatterySample(
                timestamp: start.addingTimeInterval(1200),
                powerW: 40,
                percent: 44,
                maxMah: 5100,
                cycleCount: 121,
                tempC: 33,
                adapterWatts: 70
            ),
            BatterySample(
                timestamp: end,
                powerW: 50,
                percent: 46,
                maxMah: 5200,
                cycleCount: 122,
                tempC: 35,
                adapterWatts: 70
            )
        ]

        let session = Session(name: "Charger A", start: start, end: end, samples: samples)

        XCTAssertEqual(session.durationSeconds, 3600, accuracy: 0.001)
        XCTAssertEqual(session.deltaPercent, 6, accuracy: 0.001)
        XCTAssertEqual(session.percentPerHour ?? 0, 6, accuracy: 0.001)
        XCTAssertEqual(session.averageBatteryCapacityMah ?? 0, 5100, accuracy: 0.001)
        XCTAssertEqual(session.deltaMah ?? 0, 306, accuracy: 0.001)
        XCTAssertEqual(session.mahPerHour ?? 0, 306, accuracy: 0.001)
        XCTAssertEqual(session.avgChargingPowerW ?? 0, 40, accuracy: 0.001)
        XCTAssertEqual(session.peakPowerW ?? 0, 50, accuracy: 0.001)
        XCTAssertEqual(session.efficiencyPercent ?? 0, 57.142857, accuracy: 0.0001)
        XCTAssertEqual(session.avgTempC ?? 0, 33, accuracy: 0.001)
    }

    func testDischargeSessionHandledSafely() {
        let start = Date(timeIntervalSince1970: 1_700_100_000)
        let end = start.addingTimeInterval(1800)

        let samples = [
            BatterySample(timestamp: start, powerW: -10, percent: 80, maxMah: 5200, tempC: 34),
            BatterySample(timestamp: end, powerW: -25, percent: 78, maxMah: 5200, tempC: 35)
        ]

        let session = Session(start: start, end: end, samples: samples)

        XCTAssertEqual(session.deltaPercent, -2, accuracy: 0.001)
        XCTAssertEqual(session.percentPerHour ?? 0, -4, accuracy: 0.001)
        XCTAssertEqual(session.deltaMah ?? 0, -104, accuracy: 0.001)
        XCTAssertEqual(session.mahPerHour ?? 0, -208, accuracy: 0.001)
        XCTAssertNil(session.avgChargingPowerW)
        XCTAssertEqual(session.peakPowerW ?? 0, 25, accuracy: 0.001)
        XCTAssertNil(session.efficiencyPercent)
    }

    func testShortOrZeroDeltaSessionsReturnNilRates() {
        let start = Date(timeIntervalSince1970: 1_700_200_000)
        let endShort = start.addingTimeInterval(20)
        let short = Session(
            start: start,
            end: endShort,
            samples: [
                BatterySample(timestamp: start, percent: 20, maxMah: 5000),
                BatterySample(timestamp: endShort, percent: 21, maxMah: 5000)
            ]
        )

        XCTAssertNil(short.percentPerHour)
        XCTAssertNil(short.mahPerHour)

        let endNormal = start.addingTimeInterval(600)
        let noDelta = Session(
            start: start,
            end: endNormal,
            samples: [
                BatterySample(timestamp: start, percent: 30, maxMah: 5000),
                BatterySample(timestamp: endNormal, percent: 30, maxMah: 5000)
            ]
        )

        XCTAssertEqual(noDelta.deltaPercent, 0, accuracy: 0.001)
        XCTAssertNil(noDelta.percentPerHour)
        XCTAssertEqual(noDelta.deltaMah, 0)
        XCTAssertEqual(noDelta.mahPerHour, 0)

        let zeroDuration = Session(
            start: start,
            end: start,
            samples: [
                BatterySample(timestamp: start, percent: 30, maxMah: 5000),
                BatterySample(timestamp: start, percent: 33, maxMah: 5000)
            ]
        )

        XCTAssertEqual(zeroDuration.durationSeconds, 0, accuracy: 0.001)
        XCTAssertEqual(zeroDuration.deltaPercent, 3, accuracy: 0.001)
        XCTAssertNil(zeroDuration.percentPerHour)
        XCTAssertNil(zeroDuration.mahPerHour)
    }

    func testDeltaMahFallsBackToDesignConstantWhenCapacityMissing() {
        let start = Date(timeIntervalSince1970: 1_700_300_000)
        let end = start.addingTimeInterval(3600)
        let session = Session(
            start: start,
            end: end,
            samples: [
                BatterySample(timestamp: start, percent: 10),
                BatterySample(timestamp: end, percent: 20)
            ]
        )

        XCTAssertNil(session.averageBatteryCapacityMah)
        XCTAssertEqual(session.deltaMah, 600)
        XCTAssertEqual(session.mahPerHour, 600)
    }

    func testAdapterFallbackFromFirstSampleForEfficiency() {
        let start = Date(timeIntervalSince1970: 1_700_400_000)
        let end = start.addingTimeInterval(3600)
        let session = Session(
            start: start,
            end: end,
            samples: [
                BatterySample(timestamp: start, powerW: 20, percent: 50, adapterWatts: 65),
                BatterySample(timestamp: end, powerW: 30, percent: 55)
            ]
        )

        XCTAssertEqual(session.avgChargingPowerW, 25)
        XCTAssertEqual(session.adapterWatts, 65)
        XCTAssertEqual(session.efficiencyPercent ?? 0, 38.461538, accuracy: 0.0001)
    }

    func testMissingAdapterProducesNilEfficiencyForChargingSession() {
        let start = Date(timeIntervalSince1970: 1_700_500_000)
        let end = start.addingTimeInterval(1200)

        let session = Session(
            start: start,
            end: end,
            samples: [
                BatterySample(timestamp: start, powerW: 22, percent: 40),
                BatterySample(timestamp: end, powerW: 28, percent: 42)
            ]
        )

        XCTAssertEqual(session.avgChargingPowerW ?? 0, 25, accuracy: 0.001)
        XCTAssertNil(session.adapterWatts)
        XCTAssertNil(session.efficiencyPercent)
    }
}
