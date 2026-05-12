import XCTest
@testable import Domain

final class BatteryHealthPredictorTests: XCTestCase {
    func testForecastReturnsNilWhenInsufficientData() {
        let predictor = BatteryHealthPredictor()
        let observations = [
            BatteryHealthPredictor.Observation(timestamp: Date(), cycleCount: 100, healthPercent: 95),
            BatteryHealthPredictor.Observation(timestamp: Date().addingTimeInterval(86_400), cycleCount: 110, healthPercent: 94.5)
        ]

        XCTAssertNil(predictor.forecast(from: observations))
    }

    func testForecastForDecreasingHealthComputesSlopeAndCycles() {
        let predictor = BatteryHealthPredictor()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let observations = [
            BatteryHealthPredictor.Observation(timestamp: start, cycleCount: 100, healthPercent: 95),
            BatteryHealthPredictor.Observation(timestamp: start.addingTimeInterval(86_400), cycleCount: 200, healthPercent: 90),
            BatteryHealthPredictor.Observation(timestamp: start.addingTimeInterval(2 * 86_400), cycleCount: 300, healthPercent: 85)
        ]

        let forecast = predictor.forecast(from: observations, now: start)

        XCTAssertNotNil(forecast)
        XCTAssertEqual(forecast?.slope ?? 0, -0.05, accuracy: 0.0001)
        XCTAssertEqual(forecast?.intercept ?? 0, 100, accuracy: 0.0001)
        XCTAssertEqual(forecast?.r2 ?? 0, 1, accuracy: 0.0001)
        XCTAssertEqual(forecast?.cyclesTo80, 100)
        XCTAssertEqual(forecast?.cyclesTo70, 300)
        XCTAssertNotNil(forecast?.predictedAt80Date)
        XCTAssertNotNil(forecast?.predictedAt70Date)
    }

    func testForecastForNonDecreasingTrendHasNoActionableCycles() {
        let predictor = BatteryHealthPredictor()
        let observations = [
            BatteryHealthPredictor.Observation(timestamp: Date(), cycleCount: 100, healthPercent: 90),
            BatteryHealthPredictor.Observation(timestamp: Date().addingTimeInterval(86_400), cycleCount: 120, healthPercent: 90.5),
            BatteryHealthPredictor.Observation(timestamp: Date().addingTimeInterval(2 * 86_400), cycleCount: 140, healthPercent: 91)
        ]

        let forecast = predictor.forecast(from: observations)

        XCTAssertNotNil(forecast)
        XCTAssertGreaterThanOrEqual(forecast?.slope ?? -1, 0)
        XCTAssertNil(forecast?.cyclesTo80)
        XCTAssertNil(forecast?.cyclesTo70)
        XCTAssertNil(forecast?.predictedAt80Date)
        XCTAssertNil(forecast?.predictedAt70Date)
    }
}
