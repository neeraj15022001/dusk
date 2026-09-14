import AppKit
import CoreImage
import CoreText
import DuskCore

/// Offline visual verification, using generated artwork rather than screen capture.
enum EffectContactSheet {
    static func write(to url: URL) throws {
        let width = 1440, height = 98 + EffectStyle.allCases.count * 172
        let ctx = bitmap(width: width, height: height)
        ctx.setFillColor(NSColor(white: 0.95, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        label("Dusk · hinge effect study", at: CGPoint(x: 30, y: height - 42), size: 23, context: ctx)
        let ciContext = CIContext(options: [.cacheIntermediates: false])
        let source = CIImage(cgImage: EffectPreviewView.desktop)
        for (row, style) in EffectStyle.allCases.enumerated() {
            let y = Double(height - 98 - row * 172)
            label(style.title, at: CGPoint(x: 30, y: y), size: 16, context: ctx)
            for (column, p) in [0.0, 0.25, 0.5, 0.75, 1.0].enumerated() {
                let output = EffectCurve().output(progress: p, style: style)
                let rect = CGRect(x: 30 + column * 279, y: Int(y) - 132, width: 264, height: 118)
                var image = source
                if output.blurOpacity > 0 {
                    image = source.clampedToExtent().applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: output.blurOpacity * 16]).cropped(to: source.extent)
                }
                guard let rendered = ciContext.createCGImage(image, from: source.extent) else { throw failure("Failed to render \(style.title)") }
                ctx.draw(rendered, in: rect)
                let masks = bitmap(width: 264, height: 118)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(cgContext: masks, flipped: false)
                let view = EffectArtworkView(frame: CGRect(x: 0, y: 0, width: 264, height: 118))
                view.output = output
                view.draw(view.bounds)
                NSGraphicsContext.restoreGraphicsState()
                ctx.draw(masks.makeImage()!, in: rect)
                ctx.setFillColor(NSColor.black.withAlphaComponent(output.dimOpacity).cgColor)
                ctx.fill(rect)
                label("\(Int(p * 100))% closed", at: CGPoint(x: rect.minX, y: rect.minY - 17), size: 11, context: ctx)
            }
        }
        let image = NSBitmapImageRep(cgImage: ctx.makeImage()!)
        guard let data = image.representation(using: .png, properties: [:]) else { throw failure("Failed to encode effect sheet") }
        try data.write(to: url)
        print("Rendered all \(EffectStyle.allCases.count) effects at five closure positions: \(url.path)")
    }

    private static func bitmap(width: Int, height: Int) -> CGContext {
        CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    }
    private static func label(_ text: String, at position: CGPoint, size: CGFloat, context: CGContext) {
        let string = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, size, nil),
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): NSColor(white: 0.18, alpha: 1).cgColor
        ])
        context.textPosition = position
        CTLineDraw(CTLineCreateWithAttributedString(string), context)
    }
    private static func failure(_ message: String) -> NSError {
        NSError(domain: "Dusk.Render", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
