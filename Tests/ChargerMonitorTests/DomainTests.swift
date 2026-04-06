import XCTest
@testable import ChargerMonitor

final class DomainTests: XCTestCase {
    func testSessionAggregationsAndRating() throws {
        let s1 = BatterySample(timestamp: Date(), voltageV: 12.0, amperageA: 1.0, powerW: 12.0, percent: 80.0, tempC: 30.0, isCharging: true)
        let s2 = BatterySample(timestamp: Date(), voltageV: 12.0, amperageA: 1.5, powerW: 18.0, percent: 82.0, tempC: 32.0, isCharging: true)
        let s3 = BatterySample(timestamp: Date(), voltageV: 12.0, amperageA: 2.5, powerW: 30.0, percent: 85.0, tempC: 34.0, isCharging: true)

        let session = Session(start: Date().addingTimeInterval(-60), end: Date(), samples: [s1, s2, s3])

        // peakW: max of positive powerW values = 30.0
        XCTAssertEqual(session.peakW, 30.0)
        // avgW: average of positive powerW values = (12 + 18 + 30) / 3 = 20.0
        XCTAssertEqual(session.avgW, (12.0 + 18.0 + 30.0) / 3.0)
        // avgTemp: (30 + 32 + 34) / 3 = 32.0
        XCTAssertEqual(session.avgTemp, (30.0 + 32.0 + 34.0) / 3.0)
        // deltaPercent: 85 - 80 = 5
        XCTAssertEqual(session.deltaPercent, 5.0)
        // rating: avgW = 20 (< 30) → .fair
        XCTAssertEqual(session.rating, .fair)
    }

    func testSessionWithHighPower() throws {
        let s1 = BatterySample(timestamp: Date(), powerW: 65.0, percent: 10.0, isCharging: true)
        let s2 = BatterySample(timestamp: Date(), powerW: 70.0, percent: 30.0, isCharging: true)

        let session = Session(start: Date().addingTimeInterval(-300), end: Date(), samples: [s1, s2])

        XCTAssertEqual(session.peakW, 70.0)
        XCTAssertEqual(session.avgW, 67.5)
        XCTAssertEqual(session.rating, .excellent) // avgW >= 60
    }

    func testSessionDischargingIgnoredInAvgW() throws {
        let s1 = BatterySample(timestamp: Date(), powerW: -5.0, percent: 90.0)
        let s2 = BatterySample(timestamp: Date(), powerW: -3.0, percent: 88.0)

        let session = Session(start: Date().addingTimeInterval(-60), end: Date(), samples: [s1, s2])

        // No positive power values, so avgW should be nil
        XCTAssertNil(session.avgW)
        XCTAssertNil(session.peakW)
        XCTAssertEqual(session.rating, .unknown)
    }
}
