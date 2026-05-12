import XCTest
@testable import Domain
@testable import Data

final class FileSessionStoreTests: XCTestCase {
    func testSaveFetchDeleteLifecycle() async throws {
        let fm = FileManager.default
        let tmpDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let fileURL = tmpDir.appendingPathComponent("test-sessions.json")

        let store = FileSessionStore(fileURL: fileURL)

        var session = Session(start: Date().addingTimeInterval(-10), end: Date(), samples: [])
        try await store.save(session: session)

        var all = try await store.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, session.id)

        // Save update
        session.endTimestamp = Date()
        try await store.save(session: session)
        all = try await store.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, session.id)

        // Delete
        try await store.delete(sessionId: session.id)
        all = try await store.fetchAll()
        XCTAssertEqual(all.count, 0)

        // Cleanup
        try? fm.removeItem(at: tmpDir)
    }
}
