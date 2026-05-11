import Domain
import Foundation
import os

private let logger = Logger(subsystem: "com.zaryad", category: "BatteryPoller")

public actor BatteryPoller {
    public typealias Sample = BatterySample

    final class ContinuationBox: @unchecked Sendable {
        let id: UUID = UUID()
        let continuation: AsyncStream<Sample>.Continuation
        init(_ c: AsyncStream<Sample>.Continuation) { self.continuation = c }
    }

    private var continuationBoxes: [ContinuationBox] = []
    private var pollingTask: Task<Void, Never>? = nil
    private let repository: any SystemPowerRepository
    private var intervalSeconds: UInt64

    public init(repository: any SystemPowerRepository, intervalSeconds: UInt64 = 2) {
        self.repository = repository
        self.intervalSeconds = intervalSeconds
    }

    public func start(pollIntervalSeconds: UInt64? = nil) {
        if let sec = pollIntervalSeconds { self.intervalSeconds = sec }
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    let sample = try await self.repository.fetchCurrentSample()
                    self.publish(sample: sample)
                } catch {
                    logger.warning("Polling error: \(error.localizedDescription)")
                }
                let interval = self.intervalSeconds
                try? await Task.sleep(nanoseconds: interval * 1_000_000_000)
            }
        }
    }

    public func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    public func stream() -> AsyncStream<Sample> {
        let (stream, continuation) = AsyncStream<Sample>.makeStream()
        addContinuation(continuation)
        return stream
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
        logger.debug("Publishing sample to \(self.continuationBoxes.count) subscribers")
        for box in continuationBoxes {
            box.continuation.yield(sample)
        }
    }

    deinit {
        for box in continuationBoxes { box.continuation.finish() }
        pollingTask?.cancel()
    }
}
