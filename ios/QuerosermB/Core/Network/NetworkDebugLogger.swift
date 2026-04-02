import Foundation

/// Logs de rede apenas em compilações **Debug** (`-Onone` / flag `DEBUG`).
/// Em Release as chamadas viram no-op (corpo vazio).
enum NetworkDebugLogger {
    private static let maxBodyCharacters = 12_000

    static func logRequest(_ request: URLRequest) {
        #if DEBUG
        var lines: [String] = []
        lines.append("[QuerosermB API] → REQUEST")
        lines.append("\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "<nil>")")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            lines.append("Headers:")
            for key in headers.keys.sorted() {
                guard let value = headers[key] else { continue }
                let display = shouldRedactHeader(key) ? "[REDACTED]" : value
                lines.append("  \(key): \(display)")
            }
        }
        if let body = request.httpBody, !body.isEmpty {
            lines.append("Body:")
            lines.append(truncate(string: String(data: body, encoding: .utf8) ?? "<\(body.count) bytes>"))
        }
        print(lines.joined(separator: "\n"))
        #endif
    }

    static func logResponse(data: Data, response: URLResponse) {
        #if DEBUG
        var lines: [String] = []
        lines.append("[QuerosermB API] ← RESPONSE")
        if let http = response as? HTTPURLResponse {
            lines.append("Status: \(http.statusCode)")
            if let url = http.url {
                lines.append("URL: \(url.absoluteString)")
            }
        }
        lines.append("Body:")
        if let pretty = prettyJSONString(from: data) {
            lines.append(truncate(string: pretty))
        } else {
            lines.append(truncate(string: String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"))
        }
        print(lines.joined(separator: "\n"))
        #endif
    }

    static func logTransportFailure(_ error: Error) {
        #if DEBUG
        print("[QuerosermB API] ✕ TRANSPORT ERROR\n\(error.localizedDescription)")
        #endif
    }

    private static func shouldRedactHeader(_ name: String) -> Bool {
        let lower = name.lowercased()
        if lower.contains("authorization") { return true }
        if lower.contains("cmc_pro_api") || lower.contains("x-cmc") { return true }
        return lower.contains("api") && lower.contains("key")
    }

    private static func prettyJSONString(from data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
        else { return nil }
        return String(data: pretty, encoding: .utf8)
    }

    private static func truncate(string: String) -> String {
        guard string.count > maxBodyCharacters else { return string }
        let idx = string.index(string.startIndex, offsetBy: maxBodyCharacters)
        return String(string[..<idx]) + "\n… (\(string.count - maxBodyCharacters) caracteres omitidos)"
    }
}
