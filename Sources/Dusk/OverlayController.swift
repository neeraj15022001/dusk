import AppKit
import QuartzCore
import DuskCore

private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// A live WindowServer backdrop. No screenshots, private blur filters, or input interception.
final class OverlayController {
    private var panel: OverlayPanel?
    private var backdrop: NSVisualEffectView?
    private var shade: NSView?
    private var artwork: EffectArtworkView?
    private var screenNumber: UInt32?

    func update(_ output: EffectOutput) {
        guard output.progress > 0.002 else {
            hide()
            return
        }
        guard let screen = NSScreen.screens.first(where: { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return false }
            return CGDisplayIsBuiltin(id.uint32Value) != 0
        }) else { hide(); return }
        let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
        if panel == nil || id != screenNumber {
            rebuild(screen: screen)
            screenNumber = id
        }
        guard let panel else { return }
        if panel.frame != screen.frame { panel.setFrame(screen.frame, display: true) }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backdrop?.alphaValue = output.blurOpacity
        shade?.alphaValue = output.dimOpacity
        artwork?.output = output
        CATransaction.commit()
        if !panel.isVisible { panel.orderFrontRegardless() }
    }

    func hide() {
        panel?.orderOut(nil)
        backdrop?.alphaValue = 0
        shade?.alphaValue = 0
    }

    func reset() {
        hide()
        panel = nil
        backdrop = nil
        shade = nil
        artwork = nil
        screenNumber = nil
    }

    private func rebuild(screen: NSScreen) {
        reset()
        let window = OverlayPanel(contentRect: screen.frame,
                                  styleMask: [.borderless, .nonactivatingPanel],
                                  backing: .buffered, defer: false)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let root = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        let blur = NSVisualEffectView(frame: root.bounds)
        blur.autoresizingMask = [.width, .height]
        blur.blendingMode = .behindWindow
        blur.material = .hudWindow
        blur.state = .active
        blur.appearance = NSAppearance(named: .vibrantDark)
        blur.alphaValue = 0
        let dim = NSView(frame: root.bounds)
        dim.autoresizingMask = [.width, .height]
        dim.wantsLayer = true
        dim.layer?.backgroundColor = NSColor.black.cgColor
        dim.alphaValue = 0
        let shapes = EffectArtworkView(frame: root.bounds)
        shapes.autoresizingMask = [.width, .height]
        root.addSubview(blur)
        root.addSubview(shapes)
        root.addSubview(dim)
        window.contentView = root
        panel = window
        backdrop = blur
        shade = dim
        artwork = shapes
    }
}
