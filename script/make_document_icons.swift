#!/usr/bin/env swift
// Generates document icons (Resources/Images/doc_*.icns) that look like the
// icons macOS draws for CFBundleTypeIconSystemGenerated document types.
//
// macOS does not use the generated icon for content types that already have a
// system icon (e.g. public.cbz-archive shows the generic archive icon), so
// these types need an explicit CFBundleTypeIconFile instead.
//
// The layout was measured from an icon macOS generated for cooViewer (1024px):
// app icon drawn at 512px, horizontally centered, top edge at 240px; the label
// is gray (0.443), cap height 97px, baseline at 884px; the folded corner of the
// blank document stays above the app icon and casts a shadow on it.
//
// usage: swift script/make_document_icons.swift [OUTPUT_DIR] [APP_ICON.icns]
//   defaults: Resources/Images and Resources/Images/icon.icns

import AppKit
import CoreImage
import UniformTypeIdentifiers

// output name (doc_<name>.icns) -> label; one icon per CFBundleDocumentTypes entry
let icons: [(String, String)] = [
  ("cbz", "CBZ"), ("cbr", "CBR"), ("cvbdl", "CVBDL"),
  ("zip", "ZIP"), ("rar", "RAR"),
  ("jpg", "JPG"), ("png", "PNG"), ("gif", "GIF"), ("tiff", "TIFF"), ("bmp", "BMP"),
  ("pdf", "PDF"),
]

let rootDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent().path
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : rootDir + "/Resources/Images"
let appIconPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : rootDir + "/Resources/Images/icon.icns"

guard let appIcon = NSImage(contentsOfFile: appIconPath) else {
  fatalError("cannot read app icon: \(appIconPath)")
}
let blank = NSWorkspace.shared.icon(for: UTType.data)
let labelColor = NSColor(calibratedWhite: 0.443, alpha: 1)
let shadowAlpha: CGFloat = 0.7
let shadowBlur: CGFloat = 50
let shadowOffset: CGFloat = 15

func newRep(_ px: Int) -> NSBitmapImageRep {
  let r = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                           hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  r.size = NSSize(width: px, height: px)
  return r
}

// blurred black silhouette of the folded corner, shifted down
func shadowImage(_ path: NSBezierPath, _ px: Int, _ s: CGFloat) -> NSImage {
  let r = newRep(px)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: r)
  let p = path.copy() as! NSBezierPath
  p.transform(using: AffineTransform(translationByX: 0, byY: -shadowOffset * s))
  NSColor(calibratedWhite: 0, alpha: shadowAlpha).setFill()
  p.fill()
  NSGraphicsContext.restoreGraphicsState()
  let ci = CIImage(bitmapImageRep: r)!.clampedToExtent()
    .applyingGaussianBlur(sigma: Double(shadowBlur * s))
    .cropped(to: CGRect(x: 0, y: 0, width: px, height: px))
  let img = NSImage(size: NSSize(width: px, height: px))
  img.addRepresentation(NSCIImageRep(ciImage: ci))
  return img
}

// points: logical icon size; the label is omitted at 16pt like the system does
func render(_ label: String, points: Int, scale: Int) -> NSBitmapImageRep {
  let px = points * scale
  let r = newRep(px)
  let s = CGFloat(px) / 1024
  let full = NSRect(x: 0, y: 0, width: px, height: px)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: r)
  NSGraphicsContext.current!.imageInterpolation = .high

  blank.draw(in: full)

  // folded corner of the blank document (x >= 603.5, down to y = 309.5 from the top)
  let flapPath = NSBezierPath(roundedRect: NSRect(x: 603.5 * s, y: CGFloat(px) - 309.5 * s,
                                                  width: CGFloat(px) - 603.5 * s, height: 309.5 * s),
                              xRadius: 24 * s, yRadius: 24 * s)
  let flap = NSImage(size: full.size, flipped: false) { _ in
    flapPath.addClip()
    blank.draw(in: full)
    return true
  }
  // the corner's shadow falls only on the app icon (sourceAtop)
  let iconLayer = NSImage(size: full.size, flipped: false) { _ in
    appIcon.draw(in: NSRect(x: 256 * s, y: CGFloat(px) - (240 + 512) * s, width: 512 * s, height: 512 * s))
    shadowImage(flapPath, px, s).draw(in: full, from: .zero, operation: .sourceAtop, fraction: 1)
    return true
  }
  iconLayer.draw(in: full)
  flap.draw(in: full)

  if points >= 32 {
    let capRatio = NSFont.systemFont(ofSize: 100).capHeight / 100
    let font = NSFont.systemFont(ofSize: CGFloat(px) * 97 / 1024 / capRatio)
    let str = NSAttributedString(string: label, attributes: [.font: font, .foregroundColor: labelColor])
    str.draw(at: NSPoint(x: (CGFloat(px) - str.size().width) / 2, y: CGFloat(px) - 884 * s + font.descender))
  }
  NSGraphicsContext.restoreGraphicsState()
  return r
}

let fm = FileManager.default
for (name, label) in icons {
  let iconset = NSTemporaryDirectory() + "doc_\(name).iconset"
  try? fm.removeItem(atPath: iconset)
  try! fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)
  for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
      let file = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
      let png = render(label, points: points, scale: scale).representation(using: .png, properties: [:])!
      try! png.write(to: URL(fileURLWithPath: iconset + "/" + file))
    }
  }
  let p = Process()
  p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
  p.arguments = ["-c", "icns", iconset, "-o", outDir + "/doc_\(name).icns"]
  try! p.run()
  p.waitUntilExit()
  guard p.terminationStatus == 0 else { fatalError("iconutil failed for \(name)") }
  try? fm.removeItem(atPath: iconset)
  print("wrote \(outDir)/doc_\(name).icns")
}
