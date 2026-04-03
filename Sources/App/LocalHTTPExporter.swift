import Foundation
import Network

/// Simple local HTTP exporter to serve two endpoints:
/// - / or /index.html -> serves charger_dashboard.html from provided file path
/// - /data.json -> calls getJSON closure to provide JSON data

public final class LocalHTTPExporter {
    private var listener: NWListener?
    private let port: UInt16
    private let htmlPath: String?
    private let getJSON: () -> Data?

    public init(port: UInt16 = 8080, htmlPath: String? = nil, getJSON: @escaping () -> Data?) {
        self.port = port
        self.htmlPath = htmlPath
        self.getJSON = getJSON
    }

    public func start() throws {
        let portValue = NWEndpoint.Port(rawValue: port) ?? NWEndpoint.Port(8080)
        let params = NWParameters.tcp
        let listener = try NWListener(using: params, on: portValue)
        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: .global())
            self?.handle(connection: connection)
        }
        listener.start(queue: .global())
        self.listener = listener
    }

    public func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handle(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { [weak self] data, _, isComplete, error in
            guard let self = self else { connection.cancel(); return }
            guard let data = data, let req = String(data: data, encoding: .utf8) else { connection.cancel(); return }

            // Parse request line
            let firstLine = req.split(separator: "\r\n").first.map(String.init) ?? ""
            let parts = firstLine.split(separator: " ")
            let path = parts.count > 1 ? String(parts[1]) : "/"

            var body: Data? = nil
            var contentType = "text/plain; charset=utf-8"
            var statusLine = "HTTP/1.1 200 OK\r\n"

            if path == "/" || path == "/index.html" {
                if let htmlPath = self.htmlPath, FileManager.default.fileExists(atPath: htmlPath), let html = try? String(contentsOfFile: htmlPath, encoding: .utf8) {
                    body = html.data(using: .utf8)
                    contentType = "text/html; charset=utf-8"
                } else {
                    body = "<html><body><h1>charger_dashboard.html not found</h1></body></html>".data(using: .utf8)
                    contentType = "text/html; charset=utf-8"
                }
            } else if path == "/data.json" {
                body = self.getJSON() ?? Data("{}".utf8)
                contentType = "application/json; charset=utf-8"
            } else {
                statusLine = "HTTP/1.1 404 Not Found\r\n"
                body = "Not Found".data(using: .utf8)
            }

            let contentLength = body?.count ?? 0
            var header = """
            \(statusLine)Content-Length: \(contentLength)\r
            Content-Type: \(contentType)\r
            Connection: close\r
            \r
            """

            var response = Data()
            response.append(header.data(using: .utf8)!)
            if let b = body { response.append(b) }

            connection.send(content: response, completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        }
    }
}
