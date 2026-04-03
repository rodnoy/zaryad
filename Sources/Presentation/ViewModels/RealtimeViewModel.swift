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
    // Use session use-cases for proper session lifecycle handling
    private let startUseCase: any Domain.StartSessionUseCase
    private let appendUseCase: any Domain.AppendSampleToSessionUseCase
    private let stopUseCase: any Domain.StopSessionUseCase

    private var pollingTask: Task<Void, Never>? = nil
    private let maxSamples = 150

    public init(
        poller: DataLayer.Poller.CentralPoller,
        startUseCase: any Domain.StartSessionUseCase,
        appendUseCase: any Domain.AppendSampleToSessionUseCase,
        stopUseCase: any Domain.StopSessionUseCase
    ) {
        self.poller = poller
        self.startUseCase = startUseCase
        self.appendUseCase = appendUseCase
        self.stopUseCase = stopUseCase
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
        // If session active, append to session via use case
        if isSessionActive {
            Task { [sample] in
                do {
                    try await self.appendUseCase.append(sample: sample)
                } catch {
                    // ignore append errors for now
                }
            }
        }
    }

    public func toggleSession() async {
        if isSessionActive {
            // stop
            do {
                _ = try await stopUseCase.stop()
            } catch {
                // ignore for now
            }
            isSessionActive = false
        } else {
            do {
                _ = try await startUseCase.start()
                isSessionActive = true
            } catch {
                // failed to start session — keep flag false
                isSessionActive = false
            }
        }
    }
}
