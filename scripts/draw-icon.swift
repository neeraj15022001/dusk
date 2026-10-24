import AppKit

// Original vector artwork extending the website's moon-and-horizon mark.
// Draw at each native icon size so small representations stay crisp.
let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}

func drawIcon(pixels: Int) throws -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!.cgContext
    context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    let space = CGColorSpaceCreateDeviceRGB()
    let background = CGGradient(colorsSpace: space, colors: [color(7, 26, 38), color(30, 73, 81)] as CFArray, locations: [0, 1])!
    let bounds = CGRect(x: 64, y: 64, width: 896, height: 896)
    let tile = CGPath(roundedRect: bounds, cornerWidth: 202, cornerHeight: 202, transform: nil)
    context.addPath(tile)
    context.clip()
    func fillBackground() {
        context.drawLinearGradient(background, start: CGPoint(x: 850, y: 70), end: CGPoint(x: 170, y: 960), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }
    fillBackground()

    context.saveGState()
    context.addEllipse(in: CGRect(x: 226, y: 300, width: 570, height: 570))
    context.clip()
    let moon = CGGradient(colorsSpace: space, colors: [color(151, 202, 195), color(229, 242, 215)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(moon, start: CGPoint(x: 280, y: 300), end: CGPoint(x: 690, y: 860), options: [])
    context.addEllipse(in: CGRect(x: 415, y: 457, width: 530, height: 530))
    context.clip()
    fillBackground()
    context.restoreGState()

    context.setStrokeColor(color(177, 220, 212))
    context.setLineCap(.round)
    context.setLineWidth(pixels <= 32 ? 28 : 20)
    context.move(to: CGPoint(x: 250, y: 263))
    context.addLine(to: CGPoint(x: 778, y: 263))
    context.strokePath()
    if pixels >= 32 {
        context.setAlpha(0.62)
        context.move(to: CGPoint(x: 332, y: 195))
        context.addLine(to: CGPoint(x: 696, y: 195))
        context.strokePath()
    }
    return bitmap.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let suffix = scale == 2 ? "@2x" : ""
        try drawIcon(pixels: size * scale).write(to: destination.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
