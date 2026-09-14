import Foundation

public struct EffectCurve: Equatable {
    public var startAngle: Double
    public var darkAngle: Double
    public var maximumDim: Double
    public var blurStrength: Double

    public init(startAngle: Double = 65, darkAngle: Double = 8,
                maximumDim: Double = 0.96, blurStrength: Double = 1) {
        self.startAngle = startAngle
        self.darkAngle = darkAngle
        self.maximumDim = maximumDim
        self.blurStrength = blurStrength
    }

    public func progress(angle: Double) -> Double {
        guard angle.isFinite, (0...180).contains(angle),
              startAngle.isFinite, darkAngle.isFinite, startAngle > darkAngle else { return 0 }
        let fraction = min(1, max(0, (startAngle - angle) / (startAngle - darkAngle)))
        return Self.ease(fraction)
    }

    /// Maps closure (0 = open, 1 = closed) to visual intensity in 0...1.
    /// Smoothstep starts and finishes gently and is reversible without a jump.
    public static func ease(_ fraction: Double) -> Double {
        // Keep both endpoints, monotonicity, and the 0...1 output range.
        guard fraction.isFinite else { return 0 }
        let t = min(1, max(0, fraction))
        let squared = t * t
        let softened = squared * (3 - 2 * t)
        return softened
    }

    public func output(progress: Double, style: EffectStyle = .softBlur) -> EffectOutput {
        let p = progress.isFinite ? min(1, max(0, progress)) : 0
        let blur = blurStrength.isFinite ? min(1, max(0, blurStrength)) : 0
        let dim = maximumDim.isFinite ? min(0.98, max(0, maximumDim)) : 0
        switch style {
        case .softBlur:
            return EffectOutput(style: style, progress: p, blurOpacity: sqrt(p) * blur,
                                dimOpacity: pow(p, 1.65) * dim, strength: dim)
        case .fade:
            return EffectOutput(style: style, progress: p, blurOpacity: 0,
                                dimOpacity: p * dim, strength: dim)
        case .aperture, .shutters, .crt:
            return EffectOutput(style: style, progress: p, blurOpacity: 0,
                                dimOpacity: 0, strength: dim)
        }
    }
}

public struct EffectOutput: Equatable {
    public let style: EffectStyle
    public let progress: Double
    public let blurOpacity: Double
    public let dimOpacity: Double
    public let strength: Double
}

public enum HingeReport {
    /// Apple SPU report 1: report ID followed by a little-endian angle.
    public static func angle(from bytes: [UInt8]) -> Double? {
        guard bytes.count >= 3, bytes[0] == 1 else { return nil }
        let angle = Double(UInt16(bytes[1]) | UInt16(bytes[2]) << 8)
        guard (0...180).contains(angle) else { return nil }
        return angle
    }
}
