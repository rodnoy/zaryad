import Foundation
import SwiftData

public final class HealthSnapshotStore: @unchecked Sendable {
    private let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    public func saveSnapshot(
        cycleCount: Int,
        healthPercent: Double,
        maxMah: Int?,
        designMah: Int?
    ) async throws {
        let context = modelContainer.mainContext
        let snapshot = SDHealthSnapshot(
            cycleCount: cycleCount,
            healthPercent: healthPercent,
            maxMah: maxMah,
            designMah: designMah
        )
        context.insert(snapshot)
        try context.save()
    }

    @MainActor
    public func fetchSnapshots(limit: Int) async -> [SDHealthSnapshot] {
        let context = modelContainer.mainContext
        let safeLimit = max(1, limit)
        var descriptor = FetchDescriptor<SDHealthSnapshot>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = safeLimit

        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    @MainActor
    public func deleteSnapshots(olderThan date: Date) async throws {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SDHealthSnapshot>(
            predicate: #Predicate<SDHealthSnapshot> { $0.timestamp < date }
        )
        let snapshots = try context.fetch(descriptor)
        for snapshot in snapshots {
            context.delete(snapshot)
        }
        if !snapshots.isEmpty {
            try context.save()
        }
    }
}
