import SwiftUI
import AppKit

@main
enum AppMain {
    static func main() {
        // Hidden mode used to render the README screenshot: `ClaudeLimits --snapshot <path>`.
        if let i = CommandLine.arguments.firstIndex(of: "--snapshot") {
            let path = CommandLine.arguments.count > i + 1 ? CommandLine.arguments[i + 1] : "screenshot.png"
            Snapshotter.render(to: path)
            return
        }
        ClaudeLimitsApp.main()
    }
}

struct ClaudeLimitsApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            DropdownView(store: store)
        } label: {
            Text(store.menuTitle)
                .onAppear { store.startIfNeeded() }
        }
        .menuBarExtraStyle(.window)
    }
}

struct DropdownView: View {
    @ObservedObject var store: UsageStore

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()

            if store.usage == nil && (store.phase == .noToken || store.phase == .unauthorized) {
                NotSignedInView(store: store)
            } else {
                content
            }
        }
        .frame(width: 320)
        .preferredColorScheme(.light)
    }

    private var content: some View {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let u = store.usage {
                    VStack(alignment: .leading, spacing: 14) {
                        WindowRow(title: "5 hours", window: u.fiveHour)
                        WindowRow(title: "7 days", window: u.sevenDay)
                        if let s = u.sevenDaySonnet { WindowRow(title: "Sonnet · 7d", window: s) }
                        if let o = u.sevenDayOpus { WindowRow(title: "Opus · 7d", window: o) }
                    }

                    if let used = u.extraUsed, let limit = u.extraLimit {
                        line
                        HStack {
                            Text("Extra usage").foregroundStyle(Theme.inkMuted)
                            Spacer()
                            Text("\(fmt(used)) / \(fmt(limit)) \(u.extraCurrency ?? "")")
                                .foregroundStyle(Theme.ink)
                        }
                        .font(.system(size: 12))
                    }
                } else {
                    Text(store.status).font(.system(size: 13)).foregroundStyle(Theme.inkMuted)
                }

                if store.isError && store.usage != nil {
                    Text(store.status).font(.system(size: 11)).foregroundStyle(Theme.warning)
                } else if store.phase == .rateLimited && store.usage != nil {
                    Text(store.status).font(.system(size: 11)).foregroundStyle(Theme.inkMuted)
                }

                line
                footer
            }
            .padding(18)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Circle().fill(Theme.accent).frame(width: 7, height: 7)
                Text("Claude usage")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
            Text("spent this period")
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkMuted)
                .padding(.leading, 15)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text(footerText).font(.system(size: 11)).foregroundStyle(Theme.inkMuted)
            Spacer()
            PlainButton("Refresh") { Task { await store.refresh() } }
            PlainButton("Quit") { NSApplication.shared.terminate(nil) }
        }
    }

    private var line: some View { Rectangle().fill(Theme.divider).frame(height: 1) }

    private var footerText: String {
        guard let t = store.lastUpdated else { return "—" }
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return "updated \(f.string(from: t))"
    }

    private func fmt(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.2f", v)
    }
}

/// Friendly onboarding shown when no Claude Code token is available yet.
struct NotSignedInView: View {
    @ObservedObject var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle().fill(Theme.accent).frame(width: 7, height: 7)
                Text("Not signed in")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle().fill(Theme.divider).frame(height: 1)

            HStack(spacing: 10) {
                PlainButton("Open Terminal") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
                }
                Spacer()
                PlainButton("Refresh") { Task { await store.refresh() } }
                PlainButton("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(18)
    }

    private var message: String {
        store.phase == .unauthorized
            ? "Your Claude Code session has expired. Sign in again, then hit Refresh."
            : "Claude Limits reuses your Claude Code login. Open a terminal, run \"claude\" and sign in — then hit Refresh."
    }
}

struct WindowRow: View {
    let title: String
    let window: WindowUsage?

    private var used: Int { window?.used ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(used)%")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.barColor(used: used))
            }
            UsageBar(used: used)
            if let reset = resetText {
                Text(reset).font(.system(size: 11)).foregroundStyle(Theme.inkMuted)
            }
        }
    }

    private var resetText: String? {
        guard let date = window?.resetsAt else { return nil }
        let now = Date()
        let abs: String = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US")
            f.dateFormat = Calendar.current.isDate(date, inSameDayAs: now) ? "HH:mm" : "d MMM, HH:mm"
            return f.string(from: date)
        }()
        let secs = date.timeIntervalSince(now)
        guard secs > 0 else { return "resets: \(abs)" }
        let h = Int(secs) / 3600, m = (Int(secs) % 3600) / 60
        let rel = h > 0 ? "\(h)h \(m)m" : "\(m)m"
        return "resets \(abs) · in \(rel)"
    }
}

/// Capsule progress bar: coral fill grows with how much is spent.
struct UsageBar: View {
    let used: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule()
                    .fill(Theme.barColor(used: used))
                    .frame(width: max(0, geo.size.width * CGFloat(used) / 100))
            }
        }
        .frame(height: 7)
    }
}

/// Borderless text button in the Anthropic palette.
struct PlainButton: View {
    let title: String
    let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }

    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.accent)
        }
        .buttonStyle(.plain)
    }
}
