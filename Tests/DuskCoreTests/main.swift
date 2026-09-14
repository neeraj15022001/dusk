import Foundation
import DuskCore

var checks = 0
var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String, line: Int = #line) {
    checks += 1
    if !condition() {
        failures += 1
        fputs("FAIL line \(line): \(message)\n", stderr)
    }
}

let curve = EffectCurve()
check(curve.progress(angle: 110) == 0, "Fully open screen is clear")
check(curve.progress(angle: 65) == 0, "Start threshold is clear")
check(abs(curve.progress(angle: 36.5) - 0.5) < 0.000001, "Midpoint has half intensity")
check(curve.progress(angle: 8) == 1, "Dark threshold reaches full effect")
check(curve.progress(angle: 0) == 1, "Closed position saturates")

var previous = 0.0
for angle in stride(from: 140.0, through: 0.0, by: -0.25) {
    let progress = curve.progress(angle: angle)
    check(progress >= previous && (0...1).contains(progress), "Closing remains monotonic and bounded at \(angle)°")
    previous = progress
}
previous = 1
for angle in stride(from: 0.0, through: 140.0, by: 0.25) {
    let progress = curve.progress(angle: angle)
    check(progress <= previous && (0...1).contains(progress), "Reopening clears continuously at \(angle)°")
    previous = progress
}

for angle in [Double.nan, .infinity, -.infinity, -1, 181, 65535] {
    check(curve.progress(angle: angle) == 0, "Invalid angle fails open")
}
check(EffectCurve(startAngle: 8, darkAngle: 65).progress(angle: 40) == 0, "Inverted thresholds fail open")
check(EffectCurve(startAngle: 8, darkAngle: 8).progress(angle: 8) == 0, "Equal thresholds fail open")
check(EffectCurve(startAngle: .nan).progress(angle: 8) == 0, "NaN threshold fails open")

let clear = curve.output(progress: 0)
check(clear.blurOpacity == 0 && clear.dimOpacity == 0, "No overlay at clear state")
let dark = curve.output(progress: 1)
check(dark.blurOpacity == 1 && dark.dimOpacity == 0.96, "Full effect matches settings")
check(curve.output(progress: .nan) == clear, "Invalid intensity clears overlay")
check(curve.output(progress: 0.5).blurOpacity > curve.output(progress: 0.5).dimOpacity, "Blur arrives before darkness")
let extreme = EffectCurve(maximumDim: 9, blurStrength: 3).output(progress: 2)
check(extreme.dimOpacity == 0.98 && extreme.blurOpacity == 1, "Output respects maximum bounds")
check(EffectCurve(blurStrength: 0).output(progress: 1).blurOpacity == 0, "Blur can be turned off")
let invalid = EffectCurve(maximumDim: .nan, blurStrength: .infinity).output(progress: 1)
check(invalid.dimOpacity == 0 && invalid.blurOpacity == 0 && invalid.strength == 0, "Invalid configuration clears effect")

check(HingeReport.angle(from: [1, 110, 0, 0, 0, 0, 0, 0]) == 110, "Decodes normal hinge report")
check(HingeReport.angle(from: [1, 0, 0]) == 0, "Accepts closed lid")
check(HingeReport.angle(from: [1, 180, 0]) == 180, "Accepts maximum angle")
for bytes: [UInt8] in [[], [1, 90], [2, 90, 0], [1, 104, 1], [1, 255, 255]] {
    check(HingeReport.angle(from: bytes) == nil, "Rejects malformed or out-of-range HID report")
}

check(Set(EffectStyle.allCases.map(\.rawValue)).count == 5, "All five effect IDs are unique")
check(EffectStyle(rawValue: "unknown") == nil, "Unknown saved effects can fall back safely")
for style in EffectStyle.allCases {
    let start = curve.output(progress: 0, style: style)
    check(start.progress == 0 && start.blurOpacity == 0 && start.dimOpacity == 0, "\(style.title) begins clear")
    check(curve.output(progress: .nan, style: style) == start, "\(style.title) handles invalid progress")
    let end = curve.output(progress: 1, style: style)
    check(end.progress == 1 && end.strength == 0.96, "\(style.title) reaches configured closure")
    if !style.usesBlur { check(end.blurOpacity == 0, "\(style.title) never adds blur") }
}
let radius = EffectGeometry.apertureRadius(progress: 0, width: 1440, height: 900)
check(radius * cos(.pi / 8) >= hypot(1440.0, 900.0) / 2 - 0.001, "Open aperture encloses screen corners")
check(EffectGeometry.apertureRadius(progress: 1, width: 1440, height: 900) == 0, "Aperture closes completely")
var lastRadius = Double.infinity
var lastArea = Double.infinity
for step in 0...100 {
    let p = Double(step) / 100
    let radius = EffectGeometry.apertureRadius(progress: p, width: 1440, height: 900)
    let crt = EffectGeometry.crtOpening(progress: p)
    check(radius <= lastRadius, "Aperture closure is monotonic")
    check(crt.width * crt.height <= lastArea, "CRT opening shrinks monotonically")
    lastRadius = radius; lastArea = crt.width * crt.height
}
let crtOpen = EffectGeometry.crtOpening(progress: 0)
let crtClosed = EffectGeometry.crtOpening(progress: 1)
check(crtOpen.width == 1 && crtOpen.height == 1, "CRT begins fully open")
check(crtClosed.width == 0 && crtClosed.height == 0, "CRT ends closed")
print("\(checks - failures)/\(checks) checks passed (five effects, geometry, HID decoding).")
exit(failures == 0 ? 0 : 1)
