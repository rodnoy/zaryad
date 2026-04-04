import Combine
import SwiftUI
import os

private let logger = Logger(subsystem: "com.chargermonitor", category: "RealtimeViewModel")

@MainActor
public final class RealtimeViewModel: ObservableObject {
    @Published public private(set) var currentSample: BatterySample?
    @Published public private(set) var recentSamples: [BatterySample] = []
    @Published public private(set) var isSessionActive: Bool = false
    @Published public private(set) var connectionStatus: ConnectionStatus = .disconnected

    public enum ConnectionStatus {
        case connected, disconnected, error
    }

    private let poller: BatteryPoller
    private let sessionManager: SessionManager

    private var pollingTask: Task<Void, Never>? = nil
    private let maxSamples = 150

    public init(poller: BatteryPoller, sessionManager: SessionManager) {
        self.poller = poller
        self.sessionManager = sessionManager
    }

    public func startPolling(pollIntervalSeconds: UInt64 = 2) async {
        logger.info("Starting polling with interval \(pollIntervalSeconds)s")

        // Ensure previous pipeline is fully stopped before starting a new one.
        await stopPolling()

        // Subscribe first to avoid missing the first published sample.
        let stream = await poller.stream()

        pollingTask = Task { [weak self] in
            guard let self else { return }
            for await sample in stream {
                await self.handle(sample: sample)
            }
            await MainActor.run {
                self.connectionStatus = .disconnected
            }
        }

        await poller.start(pollIntervalSeconds: pollIntervalSeconds)
    }

    public func stopPolling() async {
        logger.info("Stopping polling")
        pollingTask?.cancel()
        pollingTask = nil
        await poller.stop()
        connectionStatus = .disconnected
    }

    private func handle(sample: BatterySample) async {
        logger.debug("Received sample: power=\(sample.powerW ?? 0, privacy: .public)W percent=\(sample.percent ?? 0, privacy: .public)")
        self.currentSample = sample
        self.connectionStatus = .connected
        self.recentSamples.append(sample)
        if self.recentSamples.count > maxSamples {
            self.recentSamples.removeFirst(self.recentSamples.count - maxSamples)
        }
        if isSessionActive {
            try? await sessionManager.append(sample: sample)
        }
    }

    public func startSession(name: String?) async {
        do {
            _ = try await sessionManager.start(name: name)
            isSessionActive = true
        } catch {
            isSessionActive = false
        }
    }

    public func stopSession() async {
        do {
            _ = try await sessionManager.stop()
        } catch {
            // ignore
        }
        isSessionActive = false
    }

    public func toggleSession(name: String? = nil) async {
        if isSessionActive {
            await stopSession()
        } else {
            await startSession(name: name)
        }
    }
}
