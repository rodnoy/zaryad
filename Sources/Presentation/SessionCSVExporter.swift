import Domain
import Foundation

public struct SessionCSVExporter {
    private let isoFormatter: ISO8601DateFormatter

    public init() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = formatter
    }

    public func exportSessions(_ sessions: [Session], to url: URL) throws {
        let csv = makeCSV(for: sessions)
        try csv.write(to: url, atomically: true, encoding: .utf8)
    }

    public func exportSingleSession(session: Session, url: URL) throws {
        let csv = makeCSV(for: [session])
        try csv.write(to: url, atomically: true, encoding: .utf8)
    }

    private func makeCSV(for sessions: [Session]) -> String {
        let header = [
            "sessionId", "name", "start_iso", "end_iso", "duration_s", "delta_percent", "percent_per_hour",
            "delta_mah", "mah_per_hour", "avg_w", "peak_w", "avg_temp_c", "adapter_watts", "cycles_start",
            "cycles_end", "health_start", "health_end", "samples_count"
        ]

        let lines = [header] + sessions.map { row(for: $0) }
        return lines
            .map { $0.map(csvEscape).joined(separator: ",") }
            .joined(separator: "\r\n") + "\r\n"
    }

    private func row(for session: Session) -> [String] {
        let first = session.samples.first
        let last = session.samples.last

        return [
            session.id.uuidString,
            session.name ?? "",
            isoFormatter.string(from: session.startTimestamp),
            session.endTimestamp.map { isoFormatter.string(from: $0) } ?? "",
            formatDouble(session.durationSeconds),
            formatDouble(session.deltaPercent),
            formatDouble(session.percentPerHour),
            formatDouble(session.deltaMah),
            formatDouble(session.mahPerHour),
            formatDouble(session.avgChargingPowerW),
            formatDouble(session.peakPowerW),
            formatDouble(session.avgTempC),
            formatDouble(session.adapterWatts),
            first?.cycleCount.map(String.init) ?? "",
            last?.cycleCount.map(String.init) ?? "",
            formatDouble(first?.healthPercent),
            formatDouble(last?.healthPercent),
            String(session.samples.count)
        ]
    }

    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func formatDouble(_ value: Double?) -> String {
        guard let value else { return "" }
        var text = String(format: "%.6f", value)
        while text.contains(".") && text.last == "0" {
            text.removeLast()
        }
        if text.last == "." {
            text.removeLast()
        }
        return text
    }
}
