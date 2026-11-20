#!/usr/bin/env swift
// Renders the Diesel Ready app icon: a simple geometric amber cog on navy, no text.
//
//     swift scripts/render-app-icon.swift
//
// Writes into DieselReady/Resources/Assets.xcassets/AppIcon.appiconset:
//   AppIcon.png         1024×1024, opaque (no alpha channel), navy background
//   AppIcon-dark.png    1024×1024, amber cog on a transparent background (the system draws the dark backdrop)
//   AppIcon-tinted.png  1024×1024, greyscale cog on black (the system applies the tint)
// and docs/site/diesel-ready/icon.png at 176×176 for the website.
//
// Apple frameworks only (CoreGraphics, ImageIO).

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconSet = root.appendingPathComponent("DieselReady/Resources/Assets.xcassets/AppIcon.appiconset")
let site = root.appendingPathComponent("docs/site/diesel-ready")

func rgb(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

let navy = rgb(0x0F2A3D)
let deepBlue = rgb(0x163A52)
let amber = rgb(0xF2A33A)

/// The cog outline (teeth plus body) with a round hole, centred in a 1024 square.
func cogPath() -> CGPath {
    let centre = CGPoint(x: 512, y: 512)
    let teeth = 10
    let tipRadius: CGFloat = 372
    let rootRadius: CGFloat = 300
    let pitch = 2 * CGFloat.pi / CGFloat(teeth)
    let tipHalf = pitch * 0.20   // half the angular width at the tip
    let baseHalf = pitch * 0.29  // half the angular width at the root

    func point(_ radius: CGFloat, _ angle: CGFloat) -> CGPoint {
        CGPoint(x: centre.x + radius * cos(angle), y: centre.y + radius * sin(angle))
    }

    let path = CGMutablePath()
    let start = -CGFloat.pi / 2 // first tooth points straight up
    for index in 0..<teeth {
        let a = start + CGFloat(index) * pitch
        if index == 0 { path.move(to: point(rootRadius, a - baseHalf)) }
        path.addLine(to: point(tipRadius, a - tipHalf))
        path.addArc(center: centre, radius: tipRadius, startAngle: a - tipHalf, endAngle: a + tipHalf, clockwise: false)
        path.addLine(to: point(rootRadius, a + baseHalf))
        path.addArc(center: centre, radius: rootRadius, startAngle: a + baseHalf,
                    endAngle: a + pitch - baseHalf, clockwise: false)
    }
    path.closeSubpath()
    // Centre hole, cut out with the even-odd rule.
    path.addEllipse(in: CGRect(x: centre.x - 128, y: centre.y - 128, width: 256, height: 256))
    return path
}

enum Variant { case standard, dark, tinted }

func render(_ variant: Variant, size: Int = 1024) -> CGImage {
    let opaque = variant != .dark
    let space = variant == .tinted ? CGColorSpaceCreateDeviceGray() : CGColorSpace(name: CGColorSpace.sRGB)!
    let info: UInt32 = variant == .tinted
        ? CGImageAlphaInfo.none.rawValue
        : (opaque ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: info)!
    ctx.interpolationQuality = .high
    ctx.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    let full = CGRect(x: 0, y: 0, width: 1024, height: 1024)

    switch variant {
    case .standard:
        // Gentle navy-to-deep-blue gradient, lighter at the top.
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  colors: [deepBlue, navy] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 1024), end: CGPoint(x: 512, y: 0), options: [])
    case .dark:
        ctx.clear(full)
    case .tinted:
        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fill(full)
    }

    let cog = cogPath()
    let fill: CGColor = variant == .tinted ? CGColor(gray: 0.92, alpha: 1) : amber
    ctx.addPath(cog)
    ctx.setFillColor(fill)
    ctx.fillPath(using: .evenOdd)
    // Round off the tooth corners by stroking the outline in the same colour.
    ctx.addPath(cog)
    ctx.setStrokeColor(fill)
    ctx.setLineWidth(22)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    return ctx.makeImage()!
}

func write(_ image: CGImage, to url: URL) {
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("Could not write \(url.path)") }
    print("Wrote \(url.path.replacingOccurrences(of: root.path + "/", with: ""))")
}

write(render(.standard), to: iconSet.appendingPathComponent("AppIcon.png"))
write(render(.dark), to: iconSet.appendingPathComponent("AppIcon-dark.png"))
write(render(.tinted), to: iconSet.appendingPathComponent("AppIcon-tinted.png"))
write(render(.standard, size: 176), to: site.appendingPathComponent("icon.png"))
