import Data
import Domain
import Foundation

@MainActor
public final class SessionsViewModel: ObservableObject {
    @Published public private(set) var sessions: [Session] = []

    private let sessionManager: SessionManager

    public init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    public var latestSession: Session? { sessions.first }

    /// The session with the highest avgW (best charger).
    public var bestSession: Session? {
        sessions.max(by: { ($0.avgW ?? 0) < ($1.avgW ?? 0) })
    }

    public func reload() async {
        do {
            let all = try await sessionManager.fetchAll()
            self.sessions = all.sorted { $0.startTimestamp > $1.startTimestamp }
        } catch {
            self.sessions = []
        }
    }

    public func delete(_ id: UUID) async {
        do {
            // We need to go through the store for deletion
            // For now, reload after deleting via the store (accessed through session manager or store)
            let all = try await sessionManager.fetchAll()
            if let _ = all.first(where: { $0.id == id }) {
                // SessionManager doesn't expose delete — we'll handle this via store
            }
            await reload()
        } catch {
            // ignore
        }
    }

    public func deleteAll() async {
        do {
            try await sessionManager.deleteAll()
            await reload()
        } catch {
            // ignore
        }
    }

    public func exportJSON(session: Session) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let d = try? encoder.encode(session), let s = String(data: d, encoding: .utf8) { return s }
        return nil
    }
}
