import XCTest
@testable import Domain
@testable import Presentation

final class SessionCSVExportTests: XCTestCase {
    func testExportSingleSessionProducesRFC4180QuotedCSV() throws {
        let exporter = SessionCSVExporter()
        let start = Date(timeIntervalSince1970: 1_710_000_000)
        let end = start.addingTimeInterval(3600)
        let session = Session(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "65W, \"Office\"",
            start: start,
            end: end,
            samples: [
                BatterySample(
                    timestamp: start,
                    powerW: 12.5,
                    percent: 40,
                    maxMah: 5000,
                    designMah: 6000,
                    cycleCount: 100,
                    tempC: 30,
                    adapterWatts: 65
                ),
                BatterySample(
                    timestamp: end,
                    powerW: 34.75,
                    percent: 46,
                    maxMah: 5000,
                    designMah: 6000,
                    cycleCount: 101,
                    tempC: 32,
                    adapterWatts: 65
                )
            ]
        )

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("session-single-\(UUID().uuidString).csv")

        try exporter.exportSession(session, to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let output = try String(contentsOf: fileURL, encoding: .utf8)
        let rows = output
            .components(separatedBy: CharacterSet.newlines)
            .filter { !$0.isEmpty }

        XCTAssertEqual(rows.count, 2)
        guard rows.count >= 2 else { return }
        XCTAssertTrue(rows[0].contains("\"sessionId\""))
        XCTAssertTrue(rows[1].contains("\"65W, \"\"Office\"\"\""))
        XCTAssertTrue(rows[1].contains("\"6\""))
        XCTAssertTrue(rows[1].contains("\"23.625\""))
        XCTAssertTrue(rows[1].contains("\"34.75\""))
    }

    func testExportSessionsIncludesAllRowsAndEdgeValues() throws {
        let exporter = SessionCSVExporter()
        let start = Date(timeIntervalSince1970: 1_720_000_000)

        let chargeSession = Session(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "Charger A",
            start: start,
            end: start.addingTimeInterval(1800),
            samples: [
                BatterySample(timestamp: start, powerW: 20, percent: 50, maxMah: 5100, cycleCount: 20, tempC: 31, adapterWatts: 70),
                BatterySample(timestamp: start.addingTimeInterval(1800), powerW: 30, percent: 53, maxMah: 5100, cycleCount: 21, tempC: 33, adapterWatts: 70)
            ]
        )

        let dischargeSession = Session(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            name: "Battery Use",
            start: start,
            end: start.addingTimeInterval(1800),
            samples: [
                BatterySample(timestamp: start, powerW: -10, percent: 80, tempC: 34),
                BatterySample(timestamp: start.addingTimeInterval(1800), powerW: -15, percent: 78, tempC: 35)
            ]
        )

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("session-multi-\(UUID().uuidString).csv")

        try exporter.exportSessions([chargeSession, dischargeSession], to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let output = try String(contentsOf: fileURL, encoding: .utf8)
        let rows = output
            .components(separatedBy: CharacterSet.newlines)
            .filter { !$0.isEmpty }

        XCTAssertEqual(rows.count, 3)
        guard rows.count >= 3 else { return }
        XCTAssertTrue(rows[0].contains("\"sessionId\""))
        XCTAssertTrue(rows[1].contains("\"22222222-2222-2222-2222-222222222222\""))
        XCTAssertTrue(rows[2].contains("\"33333333-3333-3333-3333-333333333333\""))
        XCTAssertTrue(rows[2].contains("\"-2\""))
        XCTAssertTrue(rows[2].contains("\"\""))
    }
}
