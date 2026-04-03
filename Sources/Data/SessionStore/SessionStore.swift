import Foundation
import Domain

extension DataLayer {
    public enum SessionStore { }
}

extension DataLayer.SessionStore {
    public protocol SessionStore {
    func save(session: Domain.Session) async throws
    func fetchAll() async throws -> [Domain.Session]
    func delete(sessionId: UUID) async throws
}
}

