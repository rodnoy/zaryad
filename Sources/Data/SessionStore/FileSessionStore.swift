import Domain
import Foundation

public final class FileSessionStore: SessionStoreProtocol, @unchecked Sendable {
    private let fileURL: URL

    public init(fileURL: URL? = nil) {
        let fm = FileManager.default
        let base = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appFolder = base?.appendingPathComponent("ChargerMonitor")
        if let appFolder = appFolder {
            try? fm.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        self.fileURL = fileURL ?? appFolder?.appendingPathComponent("sessions.json") ?? URL(fileURLWithPath: "./sessions.json")
    }

    public func save(session: Session) async throws {
        var all = try await fetchAll()
        if let idx = all.firstIndex(where: { $0.id == session.id }) {
            all[idx] = session
        } else {
            all.append(session)
        }
        let data = try JSONEncoder().encode(all)
        try data.write(to: fileURL, options: .atomic)
    }

    public func fetchAll() async throws -> [Session] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Foundation.Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Session].self, from: data)
    }

    public func delete(sessionId: UUID) async throws {
        var all = try await fetchAll()
        all.removeAll { $0.id == sessionId }
        let data = try JSONEncoder().encode(all)
        try data.write(to: fileURL, options: .atomic)
    }

    public func deleteAll() async throws {
        let data = try JSONEncoder().encode([Session]())
        try data.write(to: fileURL, options: .atomic)
    }
}
