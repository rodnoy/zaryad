import Foundation
import Domain
import Data

@MainActor
public final class SessionsViewModel: ObservableObject {
    @Published public private(set) var sessions: [Domain.Session] = []

    private let store: DataLayer.SessionStore.SessionStore

    public init(store: DataLayer.SessionStore.SessionStore) {
        self.store = store
    }

    public var latestSession: Domain.Session? { sessions.first }

    public func reload() async {
        do {
            let all = try await store.fetchAll()
            // sort by start desc
            self.sessions = all.sorted { $0.startTimestamp > $1.startTimestamp }
        } catch {
            self.sessions = []
        }
    }

    public func delete(_ id: UUID) async {
        do {
            try await store.delete(sessionId: id)
            await reload()
        } catch {
            // ignore for now
        }
    }

    public func exportJSON(session: Domain.Session) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let d = try? encoder.encode(session), let s = String(data: d, encoding: .utf8) { return s }
        return nil
    }
}
