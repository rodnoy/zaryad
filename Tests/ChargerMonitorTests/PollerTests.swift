import XCTest
import Domain
import Data

final class PollerTests: XCTestCase {
    class MockRepo: DataLayer.SystemPower.SystemPowerRepository {
        var counter = 0
        func fetchCurrentSample() async throws -> Domain.BatterySample {
            counter += 1
            return BatterySample(timestamp: Date(), voltageV: nil, amperageA: nil, powerW: Double(counter), percent: nil, currentMah: nil, maxMah: nil, designMah: nil, cycleCount: nil, tempC: nil, isCharging: nil, pluggedIn: nil, fullyCharged: nil, timeRemainingMin: nil, adapterWatts: nil)
        }
    }

    func testCentralPollerEmitsSamples() async throws {
        let repo = MockRepo()
        let poller = DataLayer.Poller.CentralPoller(repository: repo, intervalSeconds: 1)

        let stream = await poller.stream()

        // Collect first 3 values from stream with a timeout
        let task = Task.detached { () -> [Double] in
            var out: [Double] = []
            for await sample in stream {
                if let p = sample.powerW { out.append(p) }
                if out.count >= 3 { break }
            }
            return out
        }

        await poller.start(pollIntervalSeconds: 1)

        // Wait for task to finish (with timeout guard)
        let result = try await withThrowingTaskGroup(of: [Double].self) { group -> [Double] in
            group.addTask { await task.value }
            // timeout task
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
