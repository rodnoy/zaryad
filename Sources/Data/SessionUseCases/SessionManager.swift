import Foundation
import Domain

extension DataLayer {
    public enum SessionUseCases { }
}

public final class SessionManager: StartSessionUseCase, AppendSampleToSessionUseCase, StopSessionUseCase, GetSessionsUseCase {
    private let store: DataLayer.SessionStore.SessionStore
    private var current: Domain.Session?
    private let lock = NSLock()

    public init(store: DataLayer.SessionStore.SessionStore) {
        self.store = store
    }

    public func start() async throws -> Session {
        lock.lock()
        defer { lock.unlock() }
        // If a session is active, finalize it first
        if let active = current {
            var finished = active
            finished.endTimestamp = Date()
            try await store.save(session: finished)
        }
        let s = Domain.Session(start: Date())
        current = s
        return s
    }

    public func append(sample: BatterySample) async throws {
        lock.lock()
        var session = current
        if session == nil {
            // start implicit session
            session = Domain.Session(start: sample.timestamp)
        }
        session?.samples.append(sample)
        current = session
        lock.unlock()
    }

    public func stop() async throws -> Session {
        lock.lock()
        guard var session = current else {
            lock.unlock()
            throw NSError(domain: "SessionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active session"]) 
        }
        session.endTimestamp = Date()
        current = nil
        lock.unlock()

        // perform any final aggregations if needed (Session has computed props)
        try await store.save(session: session)
        return session
    }

    public func fetchAll() async throws -> [Session] {
        return try await store.fetchAll()
    }
}
