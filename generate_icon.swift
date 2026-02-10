#!/usr/bin/env swift
import AppKit

// (pixel size, filename)
let sizes: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

let outputDir = "LoudAlerts/Resources/Assets.xcassets/AppIcon.appiconset"

for (pixelSize, filename) in sizes {
    // Use NSBitmapImageRep directly to control exact pixel dimensions
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize) // 1:1 pixel mapping

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    let cgContext = context.cgContext

    let s = CGFloat(pixelSize)
    let rect = CGRect(x: 0, y: 0, width: s, height: s)

    // Rounded rect background
    let cornerRadius = s * 0.2
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    cgContext.addPath(path)
    cgContext.clip()

    // Gradient: deep orange to red
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 1.0, green: 0.45, blue: 0.1, alpha: 1.0),
        CGColor(red: 0.9, green: 0.2, blue: 0.15, alpha: 1.0),
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
        cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    }

    // Draw bell symbol
    let symbolPointSize = s * 0.55
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .bold)
    if let symbol = NSImage(systemSymbolName: "bell.badge.fill", accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig) {
        // Create a white-tinted version
        let tinted = NSImage(size: NSSize(width: s, height: s), flipped: false) { drawRect in
            symbol.draw(in: NSRect(
                x: (s - symbol.size.width) / 2,
                y: (s - symbol.size.height) / 2,
                width: symbol.size.width,
                height: symbol.size.height
            ))
            NSColor.white.set()
            drawRect.fill(using: .sourceAtop)
            return true
        }
        tinted.draw(in: NSRect(x: 0, y: 0, width: s, height: s))
    }

    NSGraphicsContext.restoreGraphicsState()

    // Save as PNG
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(filename)")
        continue
    }

    let outputPath = "\(outputDir)/\(filename)"
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Generated \(outputPath) (\(pixelSize)x\(pixelSize))")
    } catch {
        print("Failed to write \(filename): \(error)")
    }
}
