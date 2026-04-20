import Data
import Domain
import AppKit
import Foundation
import UniformTypeIdentifiers
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
    private let importExportService: SessionImportExportService

    public init(
        sessionManager: SessionManager,
        importExportService: SessionImportExportService = SessionImportExportService()
    ) {
        self.sessionManager = sessionManager
        self.importExportService = importExportService
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
        exportSelectedSessionsCSV()
    }

    public func exportAllSessions() {
        exportAllSessionsCSV()
    }

    public func exportSelectedSessionsCSV() {
        let selected = sessions.filter { selectedSessionIDs.contains($0.id) }
        exportSessions(
            selected,
            format: .csv,
            defaultName: "selected_sessions.csv",
            emptyMessageKey: "sessions.export.status.no_selection",
            successMessageKey: "sessions.export.status.success.selected_csv_format"
        )
    }

    public func exportSelectedSessionsJSON() {
        let selected = sessions.filter { selectedSessionIDs.contains($0.id) }
        exportSessions(
            selected,
            format: .json,
            defaultName: "selected_sessions.json",
            emptyMessageKey: "sessions.export.status.no_selection",
            successMessageKey: "sessions.export.status.success.selected_json_format"
        )
    }

    public func exportAllSessionsCSV() {
        exportSessions(
            sessions,
            format: .csv,
            defaultName: "all_sessions.csv",
            emptyMessageKey: "sessions.export.status.empty",
            successMessageKey: "sessions.export.status.success.all_csv_format"
        )
    }

    public func exportAllSessionsJSON() {
        exportSessions(
            sessions,
            format: .json,
            defaultName: "all_sessions.json",
            emptyMessageKey: "sessions.export.status.empty",
            successMessageKey: "sessions.export.status.success.all_json_format"
        )
    }

    public func importSessionsJSON() {
        guard let url = makeOpenURL() else {
            return
        }

        Task {
            do {
                let importedSessions = try importExportService.importSessionsJSON(from: url)
                let existingIDs = Set(try await sessionManager.fetchAll().map(\.id))
                let uniqueSessions = importedSessions.filter { !existingIDs.contains($0.id) }

                for session in uniqueSessions {
                    try await sessionManager.save(session: session)
                }

                await reload()
                exportStatus = .success(message: String(format: String(localized: "sessions.import.status.success.format"), uniqueSessions.count))
            } catch {
                logger.error("Failed to import sessions JSON: \(error.localizedDescription, privacy: .public)")
                exportStatus = .failure(message: error.localizedDescription)
            }
        }
    }

    private enum ExportFormat {
        case csv
        case json
    }

    private func exportSessions(
        _ sessionsToExport: [Session],
        format: ExportFormat,
        defaultName: String,
        emptyMessageKey: String,
        successMessageKey: String
    ) {
        guard !sessionsToExport.isEmpty else {
            exportStatus = .failure(message: NSLocalizedString(emptyMessageKey, comment: ""))
            return
        }

        let panelTitleKey = format == .csv ? "sessions.export.panel.csv.title" : "sessions.export.panel.json.title"
        let panelMessageKey = format == .csv ? "sessions.export.panel.csv.message" : "sessions.export.panel.json.message"
        let allowedType: UTType = format == .csv ? .commaSeparatedText : .json

        guard let url = makeSaveURL(
            defaultName: defaultName,
            allowedContentTypes: [allowedType],
            title: NSLocalizedString(panelTitleKey, comment: ""),
            message: NSLocalizedString(panelMessageKey, comment: "")
        ) else {
            return
        }

        do {
            switch format {
            case .csv:
                try importExportService.exportSessionsCSV(sessionsToExport, to: url)
            case .json:
                try importExportService.exportSessionsJSON(sessionsToExport, to: url)
            }

            exportStatus = .success(message: String(format: NSLocalizedString(successMessageKey, comment: ""), sessionsToExport.count))
        } catch {
            logger.error("Failed to export sessions: \(error.localizedDescription, privacy: .public)")
            exportStatus = .failure(message: error.localizedDescription)
        }
    }

    private func makeSaveURL(
        defaultName: String,
        allowedContentTypes: [UTType],
        title: String,
        message: String
    ) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = allowedContentTypes
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = defaultName
        panel.title = title
        panel.message = message

        return panel.runModal() == .OK ? panel.url : nil
    }

    private func makeOpenURL() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = String(localized: "sessions.import.panel.title")
        panel.message = String(localized: "sessions.import.panel.message")

        return panel.runModal() == .OK ? panel.url : nil
    }

    public func exportJSON(session: Session) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let d = try? encoder.encode(session), let s = String(data: d, encoding: .utf8) { return s }
        return nil
    }
}
