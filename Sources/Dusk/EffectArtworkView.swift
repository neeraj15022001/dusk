import AppKit
import SwiftUI
import DuskCore

/// Vector masks are shared by the full-screen panel and the in-window preview.
final class EffectArtworkView: NSView {
    var output = EffectCurve().output(progress: 0) {
        didSet { if output != oldValue { needsDisplay = true } }
    }
    override var isOpaque: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        let p = output.progress
        guard p > 0, bounds.width > 0, bounds.height > 0 else { return }
        switch output.style {
        case .softBlur, .fade: break
        case .aperture: drawAperture(ctx, progress: p)
        case .shutters:
            ctx.setFillColor(NSColor.black.withAlphaComponent(output.strength).cgColor)
            let h = bounds.height * p / 2
            ctx.fill(CGRect(x: 0, y: 0, width: bounds.width, height: h))
            ctx.fill(CGRect(x: 0, y: bounds.height - h, width: bounds.width, height: h))
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.10 * sin(p * .pi)).cgColor)
            ctx.setLineWidth(max(0.5, bounds.height / 900))
            ctx.move(to: CGPoint(x: 0, y: h)); ctx.addLine(to: CGPoint(x: bounds.width, y: h))
            ctx.move(to: CGPoint(x: 0, y: bounds.height - h)); ctx.addLine(to: CGPoint(x: bounds.width, y: bounds.height - h))
            ctx.strokePath()
        case .crt: drawCRT(ctx, progress: p)
        }
    }

    private func drawAperture(_ ctx: CGContext, progress p: Double) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let r = EffectGeometry.apertureRadius(progress: p, width: bounds.width, height: bounds.height)
        let rotation = p * .pi / 2
        let vertices = (0..<8).map { i in
            let a = Double(i) * .pi / 4 + rotation
            return CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
        }
        let mask = CGMutablePath()
        mask.addRect(bounds)
        if p < 1 { mask.addLines(between: vertices); mask.closeSubpath() }
        ctx.saveGState()
        ctx.addPath(mask)
        ctx.clip(using: .evenOdd)
        ctx.setFillColor(NSColor.black.withAlphaComponent(output.strength).cgColor)
        ctx.fill(bounds)
        // Tangential seams imply overlapping iris blades without covering the opening.
        let reach = hypot(bounds.width, bounds.height) * 2
        for (i, vertex) in vertices.enumerated() {
            let a = Double(i) * .pi / 4 + rotation + .pi / 2
            let outer = CGPoint(x: vertex.x + cos(CGFloat(a)) * reach,
                                y: vertex.y + sin(CGFloat(a)) * reach)
            ctx.setStrokeColor(NSColor(white: 0.32, alpha: sin(p * .pi) * 0.35).cgColor)
            ctx.setLineWidth(max(0.65, bounds.height / 1100))
            ctx.move(to: vertex); ctx.addLine(to: outer); ctx.strokePath()
        }
        ctx.restoreGState()
    }

    private func drawCRT(_ ctx: CGContext, progress p: Double) {
        let opening = EffectGeometry.crtOpening(progress: p)
        let width = bounds.width * CGFloat(opening.width)
        let height = bounds.height * CGFloat(opening.height)
        let hole = CGRect(x: (bounds.width - width) / 2,
                          y: (bounds.height - height) / 2,
                          width: width, height: height)
        let path = CGMutablePath()
        path.addRect(bounds)
        if p < 1 { path.addRect(hole) }
        ctx.addPath(path)
        ctx.setFillColor(NSColor.black.withAlphaComponent(output.strength).cgColor)
        ctx.drawPath(using: .eoFill)
        // One slow glow, driven by position. No flashing or time-based strobe.
        guard p > 0.6, p < 1 else { return }
        let glow = sin((p - 0.6) / 0.4 * .pi) * 0.32
        ctx.setShadow(offset: .zero, blur: bounds.height * 0.012,
                      color: NSColor.cyan.withAlphaComponent(glow).cgColor)
        ctx.setFillColor(NSColor(white: 0.95, alpha: glow).cgColor)
        ctx.fill(CGRect(x: hole.minX, y: bounds.midY - max(0.5, bounds.height * 0.001),
                        width: hole.width, height: max(1, bounds.height * 0.002)))
    }
}

struct EffectArtwork: NSViewRepresentable {
    let output: EffectOutput
    func makeNSView(context: Context) -> EffectArtworkView { EffectArtworkView() }
    func updateNSView(_ view: EffectArtworkView, context: Context) { view.output = output }
}
