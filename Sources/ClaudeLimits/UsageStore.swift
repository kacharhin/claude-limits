import SwiftUI

enum Phase {
    case loading, ok, noToken, unauthorized, rateLimited, error
}

@MainActor
final class UsageStore: ObservableObject {
    @Published var usage: Usage?
    @Published var status: String = "Loading…"
    @Published var lastUpdated: Date?
    @Published var isError = false
    @Published var phase: Phase = .loading

    // Polling cadence. The data moves slowly (% over 5h / 7d windows), so we
    // poll gently and back off hard when the endpoint rate-limits us (429).
    private let normalInterval: TimeInterval = 180   // 3 min
    private let minBackoff:     TimeInterval = 300    // 5 min
    private let maxBackoff:     TimeInterval = 900    // 15 min
    private var backoff:        TimeInterval = 0
    private var nextDelay:      TimeInterval = 180

    private var loop: Task<Void, Never>?
    private var started = false

    func startIfNeeded() {
        guard !started else { return }
        started = true
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refresh()
                let delay = self.nextDelay
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    func refresh() async {
        switch await UsageClient.fetch() {
        case .success(let u):
            usage = u
            lastUpdated = Date()
            isError = false
            phase = .ok
            status = "ok"
            backoff = 0
            nextDelay = normalInterval
        case .unauthorized:
            isError = true
            phase = .unauthorized
            status = "Session expired — sign in to Claude Code again"
            nextDelay = normalInterval
        case .noToken:
            isError = true
            phase = .noToken
            status = "Claude Code token not found"
            nextDelay = normalInterval
        case .rateLimited(let retryAfter):
            isError = false                  // transient; keep last data calmly
            phase = .rateLimited
            backoff = min(max(backoff * 2, minBackoff), maxBackoff)
            nextDelay = max(retryAfter ?? 0, backoff)
            let mins = max(1, Int((nextDelay / 60).rounded()))
            status = "Rate limited · try in ~\(mins) min"
        case .failure(let msg):
            isError = true
            phase = .error
            status = "Error: \(msg)"          // keep last usage on screen
            nextDelay = 60
        }
    }

    /// Compact menu-bar string: "5h 6% · 7d 9%" — spent (prefixed with ⚠ when high).
    var menuTitle: String {
        guard let f = usage?.fiveHour, let s = usage?.sevenDay else {
            return isError ? "⚠ Claude" : "… Claude"
        }
        let worst = max(f.used, s.used)
        let prefix = worst >= 80 ? "⚠ " : ""
        return "\(prefix)5h \(f.used)% · 7d \(s.used)%"
    }
}
