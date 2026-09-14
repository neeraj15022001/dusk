import Foundation

public enum EffectStyle: String, CaseIterable, Identifiable {
    case softBlur, fade, aperture, shutters, crt

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .softBlur: return "Soft blur"
        case .fade: return "Fade"
        case .aperture: return "Camera aperture"
        case .shutters: return "Cinema shutters"
        case .crt: return "CRT sleep"
        }
    }
    public var symbol: String {
        switch self {
        case .softBlur: return "drop.halffull"
        case .fade: return "moon.fill"
        case .aperture: return "camera.aperture"
        case .shutters: return "rectangle.compress.vertical"
        case .crt: return "tv"
        }
    }
    public var detail: String {
        switch self {
        case .softBlur: return "The desktop softens, then slips into darkness."
        case .fade: return "A clean fade to black, without blur or movement."
        case .aperture: return "Eight iris blades twist closed around the center."
        case .shutters: return "Two cinema curtains meet at the center of the screen."
        case .crt: return "The picture closes to a soft line, then a point."
        }
    }
    public var usesBlur: Bool { self == .softBlur }
}

/// Shared normalized geometry for the actual overlay and the miniature preview.
public enum EffectGeometry {
    public static func unit(_ value: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : 0
    }

    public static func apertureRadius(progress: Double, width: Double, height: Double) -> Double {
        hypot(width, height) / (2 * cos(.pi / 8)) * pow(1 - unit(progress), 1.25)
    }

    public static func crtOpening(progress: Double) -> (width: Double, height: Double) {
        let p = unit(progress)
        if p >= 1 { return (0, 0) }
        let squeeze = min(1, p / 0.8)
        let height = max(0.003, pow(1 - squeeze, 2.3))
        let width = pow(1 - max(0, (p - 0.8) / 0.2), 1.3)
        return (width, height)
    }
}
