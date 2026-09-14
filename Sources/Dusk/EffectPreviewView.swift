import AppKit
import SwiftUI
import CoreImage
import DuskCore

/// The preview uses the same vector masks as the desktop overlay.
final class EffectPreviewView: NSView {
    static let desktop = makeDesktop()
    private let artwork = EffectArtworkView()
    private let imageView = NSView()
    private let shade = NSView()
    private let context = CIContext(options: [.cacheIntermediates: false])
    private var lastOutput: EffectOutput?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.cornerRadius = 15
        layer?.masksToBounds = true
        for child in [imageView, artwork, shade] {
            child.frame = bounds
            child.autoresizingMask = [.width, .height]
            addSubview(child)
        }
        imageView.wantsLayer = true
        imageView.layer?.contentsGravity = .resize
        shade.wantsLayer = true
        shade.layer?.backgroundColor = NSColor.black.cgColor
        shade.alphaValue = 0
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(_ output: EffectOutput) {
        guard output != lastOutput else { return }
        lastOutput = output
        let source = CIImage(cgImage: Self.desktop)
        let processed: CIImage
        if output.blurOpacity > 0 {
            processed = source.clampedToExtent().applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: output.blurOpacity * 16]).cropped(to: source.extent)
        } else { processed = source }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageView.layer?.contents = context.createCGImage(processed, from: source.extent)
        artwork.output = output
        shade.alphaValue = output.dimOpacity
        CATransaction.commit()
    }

    static func makeDesktop() -> CGImage {
        let width = 720, height = 432
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let colors = [NSColor(red: 0.64, green: 0.77, blue: 0.76, alpha: 1).cgColor,
                      NSColor(red: 0.14, green: 0.29, blue: 0.40, alpha: 1).cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: height), options: [])
        ctx.setFillColor(NSColor(red: 0.99, green: 0.85, blue: 0.61, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: 513, y: 251, width: 87, height: 87))
        ctx.move(to: CGPoint(x: 0, y: 143))
        ctx.addCurve(to: CGPoint(x: 720, y: 162), control1: CGPoint(x: 200, y: 360), control2: CGPoint(x: 360, y: 13))
        ctx.addLine(to: CGPoint(x: 720, y: 0)); ctx.addLine(to: .zero); ctx.closePath()
        ctx.setFillColor(NSColor(red: 0.22, green: 0.46, blue: 0.48, alpha: 1).cgColor); ctx.fillPath()
        ctx.move(to: CGPoint(x: 0, y: 98))
        ctx.addCurve(to: CGPoint(x: 720, y: 171), control1: CGPoint(x: 290, y: -25), control2: CGPoint(x: 380, y: 224))
        ctx.addLine(to: CGPoint(x: 720, y: 0)); ctx.addLine(to: .zero); ctx.closePath()
        ctx.setFillColor(NSColor(red: 0.09, green: 0.25, blue: 0.31, alpha: 1).cgColor); ctx.fillPath()
        // A small document provides recognizable detail to judge blur.
        ctx.setFillColor(NSColor(white: 0.96, alpha: 0.94).cgColor)
        ctx.addPath(CGPath(roundedRect: CGRect(x: 76, y: 134, width: 270, height: 195), cornerWidth: 11, cornerHeight: 11, transform: nil))
        ctx.fillPath()
        for (i, color) in [NSColor.systemRed, .systemYellow, .systemGreen].enumerated() {
            ctx.setFillColor(color.cgColor); ctx.fillEllipse(in: CGRect(x: 90 + i * 16, y: 310, width: 8, height: 8))
        }
        ctx.setFillColor(NSColor(red: 0.18, green: 0.38, blue: 0.43, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 98, y: 267, width: 145, height: 11))
        ctx.setFillColor(NSColor(white: 0.45, alpha: 0.35).cgColor)
        for i in 0..<5 { ctx.fill(CGRect(x: 98, y: 243 - i * 17, width: i == 4 ? 137 : 224, height: 5)) }
        ctx.setFillColor(NSColor(white: 1, alpha: 0.2).cgColor)
        ctx.fill(CGRect(x: 0, y: 407, width: 720, height: 25))
        ctx.addPath(CGPath(roundedRect: CGRect(x: 226, y: 13, width: 270, height: 48), cornerWidth: 12, cornerHeight: 12, transform: nil)); ctx.fillPath()
        for i in 0..<6 {
            ctx.setFillColor(NSColor(white: 0.96, alpha: 0.85).cgColor)
            ctx.addPath(CGPath(roundedRect: CGRect(x: 239 + i * 43, y: 23, width: 30, height: 30), cornerWidth: 7, cornerHeight: 7, transform: nil)); ctx.fillPath()
        }
        return ctx.makeImage()!
    }
}

struct DesktopPreview: NSViewRepresentable {
    let output: EffectOutput
    func makeNSView(context: Context) -> EffectPreviewView { EffectPreviewView(frame: .zero) }
    func updateNSView(_ view: EffectPreviewView, context: Context) {
        view.update(output)
        view.setAccessibilityElement(true)
        view.setAccessibilityLabel("\(output.style.title) preview, \(Int(output.progress * 100)) percent closed")
    }
}
