import SwiftUI
import AppKit

/// Renders the dropdown with mock data to a PNG — used only to produce the
/// README screenshot, never at runtime. No network, no keychain access.
@MainActor
enum Snapshotter {
    static func render(to path: String) {
        let store = UsageStore()
        store.usage = Usage(
            fiveHour: WindowUsage(used: 6, resetsAt: Date().addingTimeInterval(5_880)),
            sevenDay: WindowUsage(used: 9, resetsAt: Date().addingTimeInterval(3 * 86_400)),
            sevenDaySonnet: WindowUsage(used: 0, resetsAt: nil),
            sevenDayOpus: nil,
            extraUsed: 0, extraLimit: 4_000, extraCurrency: "EUR"
        )
        store.lastUpdated = Date()

        let view = DropdownView(store: store)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2

        guard
            let image = renderer.nsImage,
            let tiff = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
        else {
            FileHandle.standardError.write(Data("snapshot: render failed\n".utf8))
            return
        }

        do {
            try png.write(to: URL(fileURLWithPath: path))
            print("snapshot written: \(path)")
        } catch {
            FileHandle.standardError.write(Data("snapshot: \(error)\n".utf8))
        }
    }
}
