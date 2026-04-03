import XCTest
import Domain

final class DomainTests: XCTestCase {
    func testSessionAggregationsAndRating() throws {
        let s1 = BatterySample(timestamp: Date(), voltageV: 12.0, amperageA: 1.0, powerW: 12.0, percent: 80.0, currentMah: nil, maxMah: nil, designMah: nil, cycleCount: nil, tempC: 30.0, isCharging: false, pluggedIn: false, fullyCharged: false, timeRemainingMin: nil, adapterWatts: nil)
        let s2 = BatterySample(timestamp: Date(), voltageV: 12.0, amperageA: 1.5, powerW: 18.0, percent: 78.0, currentMah: nil, maxMah: nil, designMah: nil, cycleCount: nil, tempC: 32.0, isCharging: false, pluggedIn: false, fullyCharged: false, timeRemainingMin: nil, adapterWatts: nil)
        let s3 = BatterySample(timestamp: Date(), voltageV: 12.0, amperageA: 2.5, powerW: 30.0, percent: 75.0, currentMah: nil, maxMah: nil, designMah: nil, cycleCount: nil, tempC: 34.0, isCharging: false, pluggedIn: false, fullyCharged: false, timeRemainingMin: nil, adapterWatts: nil)

        var session = Session(start: Date().addingTimeInterval(-60), end: Date(), samples: [s1, s2, s3])

        XCTAssertEqual(session.peakW, 30.0)
        XCTAssertEqual(session.avgW, (12.0 + 18.0 + 30.0) / 3.0)
        XCTAssertEqual(session.avgTemp, (30.0 + 32.0 + 34.0) / 3.0)
        XCTAssertEqual(session.deltaPercent, 75.0 - 80.0)

        // Based on heuristic in Session.rating we expect a deterministic value for this input.
        // Compute expected rating following the implementation rules in Session.swift
        // Start with 50
        // avgTemp = 32 -> <=40 => +10 => 60
        // peak = 30 -> peak < 30 is false; peak < 60 => +5 => 65
        // delta = -5 -> negative => -5 => 60
        // duration = 60s -> >30, so no short-session penalty
        // final: 60
        XCTAssertEqual(session.rating, 60)
    }
}
