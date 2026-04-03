import Domain
import Data

import Combine
import SwiftUI

@MainActor
public final class RealtimeViewModel: ObservableObject {
    @Published public private(set) var currentSample: Domain.BatterySample?
    @Published public private(set) var recentSamples: [Domain.BatterySample] = []
    @Published public private(set) var isSessionActive: Bool = false

    private let poller: DataLayer.Poller.CentralPoller
    private let sessionStore: DataLayer.SessionStore.SessionStore

    private var pollingTask: Task<Void, Never>? = nil
    private let maxSamples = 150

    public init(poller: DataLayer.Poller.CentralPoller, sessionStore: DataLayer.SessionStore.SessionStore) {
        self.poller = poller
        self.sessionStore = sessionStore
    }

    public func startPolling(pollIntervalSeconds: UInt64 = 2) async {
        stopPolling()

        // Start poller with desired interval
        await poller.start(pollIntervalSeconds: pollIntervalSeconds)

        // Subscribe to poller's async stream
        pollingTask = Task { [weak self] in
            guard let self = self else { return }
            for await sample in await self.poller.stream() {
                await self.handle(sample: sample)
            }
        }
    }

    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        Task { await poller.stop() }
    }

    private func handle(sample: Domain.BatterySample) async {
        self.currentSample = sample
        self.recentSamples.append(sample)
        if self.recentSamples.count > maxSamples {
            self.recentSamples.removeFirst(self.recentSamples.count - maxSamples)
        }
        // If session active, append to store (simplified)
        if isSessionActive {
            // TODO: delegate to session use case
        }
    }

    public func toggleSession() async {
        if isSessionActive {
            // stop
            isSessionActive = false
            // TODO: stop session usecase
        } else {
            isSessionActive = true
            // TODO: start session usecase
        }
    }
}
