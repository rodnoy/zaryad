import Data
import Domain
import AppKit
import Foundation
import os

private let logger = Logger(subsystem: "com.chargermonitor", category: "SessionsViewModel")

@MainActor
public final class SessionsViewModel: ObservableObject {
    @Published public private(set) var sessions: [Session] = []
    @Published public var selectedSessionIDs: Set<UUID> = []
    @Published public var exportStatus: ExportStatus?

    public enum ExportStatus: Identifiable {
        case success(message: String)
        case failure(message: String)

        public var id: String {
            switch self {
            case .success(let message): return "success-\(message)"
            case .failure(let message): return "failure-\(message)"
            }
        }

        public var titleKey: String {
            switch self {
            case .success: return "sessions.export.status.success.title"
            case .failure: return "sessions.export.status.failure.title"
            }
        }

        public var message: String {
            switch self {
            case .success(let message), .failure(let message): return message
            }
        }
    }

    private let sessionManager: SessionManager
    private let csvExporter: SessionCSVExporter

    public init(sessionManager: SessionManager, csvExporter: SessionCSVExporter = SessionCSVExporter()) {
        self.sessionManager = sessionManager
        self.csvExporter = csvExporter
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
            self.selectedSessionIDs = selectedSessionIDs.intersection(Set(self.sessions.map(\.id)))
        } catch {
            self.sessions = []
            self.selectedSessionIDs = []
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

    public func toggleSelection(_ id: UUID) {
        if selectedSessionIDs.contains(id) {
            selectedSessionIDs.remove(id)
        } else {
            selectedSessionIDs.insert(id)
        }
    }

    public func exportSelectedSessions() {
        let selected = sessions.filter { selectedSessionIDs.contains($0.id) }
        guard !selected.isEmpty else {
            exportStatus = .failure(message: String(localized: "sessions.export.status.no_selection"))
            return
        }

        guard let url = makeSaveURL(defaultName: "selected_sessions.csv") else {
            return
        }

        do {
            try csvExporter.exportSessions(selected, to: url)
            exportStatus = .success(message: String(format: String(localized: "sessions.export.status.success.selected_format"), selected.count))
        } catch {
            logger.error("Failed to export selected sessions: \(error.localizedDescription, privacy: .public)")
            exportStatus = .failure(message: error.localizedDescription)
        }
    }

    public func exportAllSessions() {
        guard !sessions.isEmpty else {
            exportStatus = .failure(message: String(localized: "sessions.export.status.empty"))
            return
        }

        guard let url = makeSaveURL(defaultName: "all_sessions.csv") else {
            return
        }

        do {
            try csvExporter.exportSessions(sessions, to: url)
            exportStatus = .success(message: String(format: String(localized: "sessions.export.status.success.all_format"), sessions.count))
        } catch {
            logger.error("Failed to export all sessions: \(error.localizedDescription, privacy: .public)")
            exportStatus = .failure(message: error.localizedDescription)
        }
    }

    private func makeSaveURL(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = defaultName
        panel.title = String(localized: "sessions.export.panel.title")
        panel.message = String(localized: "sessions.export.panel.message")

        return panel.runModal() == .OK ? panel.url : nil
    }

    public func exportJSON(session: Session) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let d = try? encoder.encode(session), let s = String(data: d, encoding: .utf8) { return s }
        return nil
    }
}
