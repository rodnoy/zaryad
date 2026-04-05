import Domain
import Foundation

public actor SessionManager: StartSessionUseCase, AppendSampleToSessionUseCase, StopSessionUseCase, GetSessionsUseCase {
    private let store: any SessionStoreProtocol
    private var current: Session?

    public init(store: any SessionStoreProtocol) {
        self.store = store
    }

    public func start(name: String? = nil) async throws -> Session {
        // If a session is active, finalize it first
        if let active = current {
            var finished = active
            finished.endTimestamp = Date()
            try await store.save(session: finished)
        }
        let s = Session(name: name, start: Date())
        current = s
        return s
    }

    public func start() async throws -> Session {
        return try await start(name: nil)
    }

    public func append(sample: BatterySample) async throws {
        if current == nil {
            current = Session(start: sample.timestamp)
        }
        current?.samples.append(sample)
    }

    public func stop() async throws -> Session {
        guard var session = current else {
            throw SessionManagerError.noActiveSession
        }
        session.endTimestamp = Date()
        current = nil
        try await store.save(session: session)
        return session
    }

    public func fetchAll() async throws -> [Session] {
        return try await store.fetchAll()
    }

    public func deleteAll() async throws {
        try await store.deleteAll()
    }
}

public enum SessionManagerError: LocalizedError {
    case noActiveSession

    public var errorDescription: String? {
        switch self {
        case .noActiveSession: return "No active session"
        }
    }
}
