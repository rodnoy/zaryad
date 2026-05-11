import Data
import Domain
import Combine
import SwiftUI
import os

private let logger = Logger(subsystem: "com.zaryad", category: "RealtimeViewModel")

@MainActor
public final class RealtimeViewModel: ObservableObject {
    @Published public private(set) var currentSample: BatterySample?
    @Published public private(set) var recentSamples: [BatterySample] = []
    @Published public private(set) var healthSnapshots: [SDHealthSnapshot] = []
    @Published public private(set) var healthForecast: BatteryHealthPredictor.Forecast?
    @Published public private(set) var isSessionActive: Bool = false
    @Published public private(set) var connectionStatus: ConnectionStatus = .disconnected

    public enum ConnectionStatus {
        case connected, disconnected, error
    }

    private let poller: BatteryPoller
    private let sessionManager: SessionManager
    private let healthSnapshotStore: HealthSnapshotStore
    private let healthPredictor = BatteryHealthPredictor()

    private var pollingTask: Task<Void, Never>? = nil
    private let maxSamples = 150
    private var lastSavedCycleCount: Int?

    public init(poller: BatteryPoller, sessionManager: SessionManager, healthSnapshotStore: HealthSnapshotStore) {
        self.poller = poller
        self.sessionManager = sessionManager
        self.healthSnapshotStore = healthSnapshotStore
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
        await refreshHealthSnapshots()
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

        await maybeSaveHealthSnapshot(sample)
    }

    private func maybeSaveHealthSnapshot(_ sample: BatterySample) async {
        guard let cycleCount = sample.cycleCount,
              let healthPercent = sample.healthPercent
        else {
            return
        }

        if lastSavedCycleCount == cycleCount {
            return
        }

        do {
            try await healthSnapshotStore.saveSnapshot(
                cycleCount: cycleCount,
                healthPercent: healthPercent,
                maxMah: sample.maxMah.map { Int($0.rounded()) },
                designMah: sample.designMah.map { Int($0.rounded()) }
            )
            lastSavedCycleCount = cycleCount
            await refreshHealthSnapshots()
        } catch {
            logger.error("Failed to save health snapshot: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func refreshHealthSnapshots(limit: Int = 120) async {
        let snapshots = await healthSnapshotStore.fetchSnapshots(limit: limit)
        self.healthSnapshots = snapshots.sorted { $0.cycleCount < $1.cycleCount }
        self.lastSavedCycleCount = self.healthSnapshots.last?.cycleCount

        let observations = self.healthSnapshots.map {
            BatteryHealthPredictor.Observation(
                timestamp: $0.timestamp,
                cycleCount: $0.cycleCount,
                healthPercent: $0.healthPercent
            )
        }
        self.healthForecast = healthPredictor.forecast(from: observations)
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
