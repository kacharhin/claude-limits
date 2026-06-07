// Draws AppIcon.png (1024×1024) in the Anthropic palette.
// Run: swift tools/make_icon.swift <out.png>
import AppKit

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let S: CGFloat = 1024

let cream  = NSColor(srgbRed: 0.941, green: 0.933, blue: 0.902, alpha: 1)
let cream2 = NSColor(srgbRed: 0.898, green: 0.886, blue: 0.847, alpha: 1)
let ink    = NSColor(srgbRed: 0.122, green: 0.118, blue: 0.114, alpha: 1)
let accent = NSColor(srgbRed: 0.851, green: 0.467, blue: 0.341, alpha: 1)
let track  = NSColor(srgbRed: 0.831, green: 0.816, blue: 0.769, alpha: 1)

let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Rounded "squircle" background with a soft vertical gradient + padding.
let pad: CGFloat = S * 0.085
let rect = CGRect(x: pad, y: pad, width: S - 2 * pad, height: S - 2 * pad)
let corner = (S - 2 * pad) * 0.225
let bg = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
ctx.saveGState()
bg.addClip()
let grad = NSGradient(starting: cream, ending: cream2)!
grad.draw(in: rect, angle: -90)
ctx.restoreGState()

// Usage gauge: a thick open arc (speedometer), ~270°, partly filled in coral.
let center = CGPoint(x: S / 2, y: S / 2 - S * 0.01)
let radius = (S - 2 * pad) * 0.30
let lw     = radius * 0.42
let startA: CGFloat = 235   // degrees
let sweep:  CGFloat = 290
let fill:   CGFloat = 0.62  // 62% spent

func arc(_ from: CGFloat, _ to: CGFloat, _ color: NSColor) {
    let p = NSBezierPath()
    p.appendArc(withCenter: center, radius: radius,
                startAngle: from, endAngle: to, clockwise: true)
    p.lineWidth = lw
    p.lineCapStyle = .round
    color.setStroke()
    p.stroke()
}
// track (full sweep), then coral fill over the first part
arc(startA, startA - sweep, track)
arc(startA, startA - sweep * fill, accent)

// Needle dot at the end of the coral fill.
let endRad = (startA - sweep * fill) * .pi / 180
let dot = CGPoint(x: center.x + cos(endRad) * radius, y: center.y + sin(endRad) * radius)
ink.setFill()
NSBezierPath(ovalIn: CGRect(x: dot.x - lw*0.28, y: dot.y - lw*0.28, width: lw*0.56, height: lw*0.56)).fill()

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("icon render failed\n".utf8)); exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("icon written: \(outPath)")
