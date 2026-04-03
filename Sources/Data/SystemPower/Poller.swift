import Foundation
import Domain

extension DataLayer {
    public enum Poller { }
}

extension DataLayer.Poller {
    public actor CentralPoller {
        public typealias Sample = Domain.BatterySample

        final class ContinuationBox {
            let id: UUID = UUID()
            let continuation: AsyncStream<Sample>.Continuation
            init(_ c: AsyncStream<Sample>.Continuation) { self.continuation = c }
        }

        private var continuationBoxes: [ContinuationBox] = []
        private var pollingTask: Task<Void, Never>? = nil
        private let repository: DataLayer.SystemPower.SystemPowerRepository
        private var intervalSeconds: UInt64

        public init(repository: DataLayer.SystemPower.SystemPowerRepository, intervalSeconds: UInt64 = 2) {
            self.repository = repository
            self.intervalSeconds = intervalSeconds
        }

        public func start(pollIntervalSeconds: UInt64? = nil) {
            if let sec = pollIntervalSeconds { self.intervalSeconds = sec }
            // stop existing
            pollingTask?.cancel()
            pollingTask = Task { [weak self] in
                guard let `self` = self else { return }
                while !Task.isCancelled {
                    do {
                        let sample = try await self.repository.fetchCurrentSample()
                        await self.publish(sample: sample)
                    } catch {
                        // ignore for now; could publish errors via separate stream
                    }
                    try? await Task.sleep(nanoseconds: self.intervalSeconds * 1_000_000_000)
                }
            }
        }

        public func stop() {
            pollingTask?.cancel()
            pollingTask = nil
        }

        public func stream() -> AsyncStream<Sample> {
            return AsyncStream { continuation in
                // Add to actor-managed list
                Task { await self.addContinuation(continuation) }
            }
        }

        private func addContinuation(_ continuation: AsyncStream<Sample>.Continuation) {
            let box = ContinuationBox(continuation)
            continuationBoxes.append(box)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id: box.id) }
            }
        }

        private func removeContinuation(id: UUID) {
            continuationBoxes.removeAll { $0.id == id }
        }

        private func publish(sample: Sample) {
            for box in continuationBoxes {
                box.continuation.yield(sample)
            }
        }

        deinit {
            for box in continuationBoxes { box.continuation.finish() }
            pollingTask?.cancel()
        }
    }
}
