import Foundation

/// One usage window (5-hour, 7-day, per-model …).
struct WindowUsage {
    let used: Int           // 0…100, = utilization (сколько потрачено)
    let resetsAt: Date?
}

/// Full snapshot returned by /api/oauth/usage.
struct Usage {
    let fiveHour: WindowUsage?
    let sevenDay: WindowUsage?
    let sevenDaySonnet: WindowUsage?
    let sevenDayOpus: WindowUsage?
    let extraUsed: Double?
    let extraLimit: Double?
    let extraCurrency: String?
}

enum FetchResult {
    case success(Usage)
    case unauthorized                       // token expired / 401
    case noToken                            // keychain item missing
    case rateLimited(retryAfter: TimeInterval?) // 429
    case failure(String)                    // network / parse error
}
