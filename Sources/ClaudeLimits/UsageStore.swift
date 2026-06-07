import SwiftUI

enum Phase {
    case loading, ok, noToken, unauthorized, error
}

@MainActor
final class UsageStore: ObservableObject {
    @Published var usage: Usage?
    @Published var status: String = "Loading…"
    @Published var lastUpdated: Date?
    @Published var isError = false
    @Published var phase: Phase = .loading

    private var timer: Timer?
    private var started = false

    func startIfNeeded() {
        guard !started else { return }
        started = true
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
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
        case .unauthorized:
            isError = true
            phase = .unauthorized
            status = "Session expired — sign in to Claude Code again"
        case .noToken:
            isError = true
            phase = .noToken
            status = "Claude Code token not found"
        case .failure(let msg):
            isError = true
            phase = .error
            status = "Error: \(msg)"        // keep last usage on screen
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
