import Foundation
import Domain

#if canImport(SwiftData)
import SwiftData
#endif

extension DataLayer.SessionStore {

/// A SessionStore implementation that prefers SwiftData when available,
/// but currently falls back to FileSessionStore for persistence to ensure
/// compatibility with macOS versions < 14.0 or when SwiftData isn't present.
public final class SwiftDataSessionStore: SessionStore {
    private let fallback: FileSessionStore

    public init(fileURL: URL? = nil) {
        self.fallback = FileSessionStore(fileURL: fileURL)
    }

    public func save(session: Domain.Session) async throws {
#if canImport(SwiftData)
        // Future: implement native SwiftData persistence here for macOS 14+.
        // For now, delegate to file-based fallback for broad compatibility.
        if #available(macOS 14.0, *) {
            // If desired, insert SwiftData-backed implementation here.
        }
#endif
        try await fallback.save(session: session)
    }

    public func fetchAll() async throws -> [Domain.Session] {
#if canImport(SwiftData)
        if #available(macOS 14.0, *) {
            // Future: load from SwiftData-backed store.
        }
#endif
        return try await fallback.fetchAll()
    }

    public func delete(sessionId: UUID) async throws {
#if canImport(SwiftData)
        if #available(macOS 14.0, *) {
            // Future: delete from SwiftData-backed store.
        }
#endif
        try await fallback.delete(sessionId: sessionId)
    }
}

}
