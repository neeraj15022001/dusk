import AppKit
import Combine
import QuartzCore
import DuskCore

final class AppModel: ObservableObject {
    @Published var enabled: Bool { didSet { defaults.set(enabled, forKey: "enabled"); if !enabled { clearEffect() } } }
    @Published var startAngle: Double { didSet { defaults.set(startAngle, forKey: "startAngle") } }
    @Published var darkAngle: Double { didSet { defaults.set(darkAngle, forKey: "darkAngle") } }
    @Published var maximumDim: Double { didSet { defaults.set(maximumDim, forKey: "maximumDim") } }
    @Published var blurStrength: Double { didSet { defaults.set(blurStrength, forKey: "blurStrength") } }
    @Published var effectStyle: EffectStyle {
        didSet {
            defaults.set(effectStyle.rawValue, forKey: "effectStyle")
            clearEffect()
        }
    }
    @Published private(set) var reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    @Published private(set) var angle: Double?
    @Published private(set) var sensorMessage = "Looking for hinge sensor…"
    @Published private(set) var progress = 0.0
    @Published private(set) var previewing = false
    @Published var hotkeyAvailable = false

    private let defaults: UserDefaults
    private let overlay = OverlayController()
    private lazy var sensor = HingeSensor { [weak self] reading in
        DispatchQueue.main.async { self?.receive(reading) }
    }
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var lastReading: TimeInterval = 0
    private var lastTick = CACurrentMediaTime()
    private var sessionStart = CACurrentMediaTime()
    private var suspended = false
    private var previewStart: TimeInterval?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["enabled": true, "startAngle": 65.0, "darkAngle": 8.0,
                                     "maximumDim": 0.96, "blurStrength": 1.0])
        enabled = defaults.bool(forKey: "enabled")
        startAngle = Self.valid(defaults.double(forKey: "startAngle"), in: 30...100, fallback: 65)
        darkAngle = Self.valid(defaults.double(forKey: "darkAngle"), in: 2...25, fallback: 8)
        maximumDim = Self.valid(defaults.double(forKey: "maximumDim"), in: 0.3...0.98, fallback: 0.96)
        blurStrength = Self.valid(defaults.double(forKey: "blurStrength"), in: 0...1, fallback: 1)
        effectStyle = EffectStyle(rawValue: defaults.string(forKey: "effectStyle") ?? "") ?? .softBlur
        // Normalize missing or retired selections without changing other preferences.
        defaults.set(effectStyle.rawValue, forKey: "effectStyle")
    }

    private static func valid(_ value: Double, in range: ClosedRange<Double>, fallback: Double) -> Double {
        value.isFinite && range.contains(value) ? value : fallback
    }

    var curve: EffectCurve {
        EffectCurve(startAngle: startAngle, darkAngle: darkAngle,
                    maximumDim: maximumDim, blurStrength: blurStrength)
    }

    var status: String {
        if previewing { return "Previewing" }
        if !enabled { return "Paused" }
        if angle == nil { return "Sensor unavailable" }
        return progress > 0.01 ? "\(effectiveStyle.title) follows your lid" : "Ready when you close"
    }

    var effectiveStyle: EffectStyle { reduceMotion ? .fade : effectStyle }

    func start() {
        sensor.start()
        let tick = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.tick() }
        tick.tolerance = 0.004
        RunLoop.main.add(tick, forMode: .common)
        timer = tick
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
                                             object: nil, queue: .main) { [weak self] _ in
            self?.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            self?.clearEffect()
        })
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
                     NSWorkspace.sessionDidResignActiveNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.suspend() })
        }
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification,
                     NSWorkspace.sessionDidBecomeActiveNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.resume() })
        }
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.overlay.reset() })
    }

    func shutdown() {
        timer?.invalidate()
        timer = nil
        sensor.stop()
        clearEffect()
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    func preview() {
        guard !suspended else { return }
        previewStart = CACurrentMediaTime()
        previewing = true
    }

    func pause() { enabled = false; clearEffect() }
    func stopPreview() { clearEffect() }

    func resetDefaults() {
        startAngle = 65
        darkAngle = 8
        maximumDim = 0.96
        blurStrength = 1
        effectStyle = .softBlur
    }

    private func receive(_ reading: HingeSensor.Reading) {
        guard !suspended, reading.time >= sessionStart else { return }
        if let value = reading.angle {
            lastReading = reading.time
            if angle != value { angle = value }
        } else {
            angle = nil
            // Do not leave an obscured desktop when the sensor becomes unreadable.
            if !previewing { progress = 0; overlay.hide() }
        }
        if sensorMessage != reading.message { sensorMessage = reading.message }
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = min(0.1, max(0, now - lastTick))
        lastTick = now
        guard !suspended else { return }
        if angle != nil, now - lastReading > 0.75 {
            angle = nil
            sensorMessage = "Hinge sensor stopped responding. Retrying…"
            if !previewing { progress = 0; overlay.hide() }
        }
        var target = 0.0
        if let began = previewStart {
            let elapsed = now - began
            if elapsed >= 4 {
                // Hard stop: preview cannot strand a dark overlay.
                clearEffect()
                return
            }
            let phase = elapsed < 2 ? elapsed / 2 : (4 - elapsed) / 2
            target = EffectCurve.ease(phase)
        } else if enabled, let angle {
            target = curve.progress(angle: angle)
        }
        let next = abs(target - progress) < 0.001 ? target : progress + (target - progress) * (1 - exp(-dt / 0.10))
        if next != progress { progress = next }
        var renderingCurve = curve
        if previewing { renderingCurve.maximumDim = min(0.65, maximumDim) }
        overlay.update(renderingCurve.output(progress: next, style: effectiveStyle))
    }

    private func clearEffect() {
        previewStart = nil
        previewing = false
        progress = 0
        overlay.hide()
    }

    private func suspend() {
        suspended = true
        sensor.stop()
        angle = nil
        clearEffect()
    }

    private func resume() {
        guard suspended else { return }
        suspended = false
        sessionStart = CACurrentMediaTime()
        lastTick = sessionStart
        sensor.start()
    }
}
