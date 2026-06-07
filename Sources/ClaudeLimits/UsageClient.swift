import Foundation

enum UsageClient {
    static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    static func fetch() async -> FetchResult {
        guard let token = KeychainReader.claudeAccessToken() else { return .noToken }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.timeoutInterval = 8

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return .failure("нет ответа") }
            if http.statusCode == 401 { return .unauthorized }
            guard http.statusCode == 200 else { return .failure("HTTP \(http.statusCode)") }
            guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure("плохой JSON")
            }

            let extra = obj["extra_usage"] as? [String: Any]
            let usage = Usage(
                fiveHour: window(obj["five_hour"]),
                sevenDay: window(obj["seven_day"]),
                sevenDaySonnet: window(obj["seven_day_sonnet"]),
                sevenDayOpus: window(obj["seven_day_opus"]),
                extraUsed: number(extra?["used_credits"]),
                extraLimit: number(extra?["monthly_limit"]),
                extraCurrency: extra?["currency"] as? String
            )
            return .success(usage)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    // MARK: - Parsing helpers

    private static func window(_ raw: Any?) -> WindowUsage? {
        guard let dict = raw as? [String: Any], let util = number(dict["utilization"]) else { return nil }
        let used = max(0, min(100, Int(util.rounded())))
        return WindowUsage(used: used, resetsAt: date(dict["resets_at"] as? String))
    }

    private static func number(_ raw: Any?) -> Double? {
        if let n = raw as? NSNumber { return n.doubleValue }
        if let d = raw as? Double { return d }
        if let i = raw as? Int { return Double(i) }
        return nil
    }

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func date(_ s: String?) -> Date? {
        guard let s else { return nil }
        if let d = isoFractional.date(from: s) { return d }
        if let d = isoPlain.date(from: s) { return d }
        // Fallback: strip fractional seconds, then parse.
        if let dot = s.firstIndex(of: "."), let plus = s.lastIndex(where: { $0 == "+" || $0 == "Z" }) {
            let stripped = String(s[s.startIndex..<dot]) + String(s[plus...])
            return isoPlain.date(from: stripped)
        }
        return nil
    }
}
