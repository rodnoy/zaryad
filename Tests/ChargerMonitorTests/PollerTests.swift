import XCTest
@testable import ChargerMonitor

final class PollerTests: XCTestCase {
    final class MockRepo: SystemPowerRepository, @unchecked Sendable {
        var counter = 0
        func fetchCurrentSample() async throws -> BatterySample {
            counter += 1
            return BatterySample(
                timestamp: Date(),
                powerW: Double(counter)
            )
        }
    }

    func testBatteryPollerEmitsSamples() async throws {
        let repo = MockRepo()
        let poller = BatteryPoller(repository: repo, intervalSeconds: 1)

        let stream = await poller.stream()

        let task = Task.detached { () -> [Double] in
            var out: [Double] = []
            for await sample in stream {
                if let p = sample.powerW { out.append(p) }
                if out.count >= 3 { break }
            }
            return out
        }

        await poller.start(pollIntervalSeconds: 1)

        let result = try await withThrowingTaskGroup(of: [Double].self) { group -> [Double] in
            group.addTask { await task.value }
            group.addTask {
                try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                return []
            }
            for try await val in group {
                if !val.isEmpty { return val }
            }
            return []
        }

        await poller.stop()

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0], 1.0)
        XCTAssertEqual(result[1], 2.0)
        XCTAssertEqual(result[2], 3.0)
    }
}
