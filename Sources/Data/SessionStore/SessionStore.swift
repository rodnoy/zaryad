import Foundation

public protocol SessionStoreProtocol: Sendable {
    func save(session: Session) async throws
    func fetchAll() async throws -> [Session]
    func delete(sessionId: UUID) async throws
    func deleteAll() async throws
}
