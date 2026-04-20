import Data
import Domain
import Foundation

public struct SessionImportExportService {
    private let csvExporter: SessionCSVExporter

    public init(csvExporter: SessionCSVExporter = SessionCSVExporter()) {
        self.csvExporter = csvExporter
    }

    public func exportSessionsJSON(_ sessions: [Session], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let payload = SessionExportPayload(version: 1, exportedAt: Date(), sessions: sessions)
        let data = try encoder.encode(payload)
        try data.write(to: url, options: .atomic)
    }

    public func importSessionsJSON(from url: URL) throws -> [Session] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let payload = try? decoder.decode(SessionExportPayload.self, from: data) {
            return payload.sessions
        }

        return try decoder.decode([Session].self, from: data)
    }

    public func exportSessionsCSV(_ sessions: [Session], to url: URL) throws {
        try csvExporter.exportSessions(sessions, to: url)
    }
}

private struct SessionExportPayload: Codable {
    let version: Int
    let exportedAt: Date
    let sessions: [Session]
}
