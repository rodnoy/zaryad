import Domain
import Foundation
import SwiftData

/// SwiftData-backed session store. Uses @Model SDSession for persistence.
public final class SwiftDataSessionStore: SessionStoreProtocol, @unchecked Sendable {
    private let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    public func save(session: Session) async throws {
        let context = modelContainer.mainContext
        let sessionID = session.id

        let descriptor = FetchDescriptor<SDSession>(
            predicate: #Predicate<SDSession> { $0.sessionID == sessionID }
        )
        let existing = try context.fetch(descriptor)

        if let sd = existing.first {
            sd.name = session.name
            sd.startTimestamp = session.startTimestamp
            sd.endTimestamp = session.endTimestamp
            sd.samplesData = (try? JSONEncoder().encode(session.samples)) ?? Data()
        } else {
            let sd = SDSession(from: session)
            context.insert(sd)
        }
        try context.save()
    }

    @MainActor
    public func fetchAll() async throws -> [Session] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SDSession>(
            sortBy: [SortDescriptor(\.startTimestamp, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return results.map { $0.toDomain() }
    }

    @MainActor
    public func delete(sessionId: UUID) async throws {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SDSession>(
            predicate: #Predicate<SDSession> { $0.sessionID == sessionId }
        )
        let results = try context.fetch(descriptor)
        for item in results {
            context.delete(item)
        }
        try context.save()
    }

    @MainActor
    public func deleteAll() async throws {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SDSession>()
        let results = try context.fetch(descriptor)
        for item in results {
            context.delete(item)
        }
        try context.save()
    }
}
