import AppKit
import SwiftUI
import DuskCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var hotkey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Accessory apps need an application menu for reliable Command-Q recovery.
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        let quitItem = appMenu.addItem(withTitle: "Quit Dusk", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)
        NSApp.mainMenu = mainMenu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "moon.haze", accessibilityDescription: "Dusk")
        statusItem.button?.toolTip = "Dusk — hinge blur and dim"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        let hotkey = GlobalHotKey { [weak self] in self?.model.pause() }
        model.hotkeyAvailable = hotkey.register()
        self.hotkey = hotkey
        model.start()
        showSettings()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let angle = model.angle.map { "\(Int($0))°" } ?? "No reading"
        menu.addItem(withTitle: "Dusk  ·  \(angle)", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: model.status, action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        add(menu, title: model.enabled ? "Pause effect" : "Enable effect", action: #selector(toggleEnabled))
        let effectsItem = menu.addItem(withTitle: "Effect", action: nil, keyEquivalent: "")
        let effectsMenu = NSMenu()
        for style in EffectStyle.allCases {
            let item = effectsMenu.addItem(withTitle: style.title, action: #selector(selectEffect(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            item.state = model.effectStyle == style ? .on : .off
        }
        effectsItem.submenu = effectsMenu
        add(menu, title: "Settings…", action: #selector(showSettings), key: ",")
        add(menu, title: "Preview for 4 seconds", action: #selector(preview))
        menu.addItem(.separator())
        add(menu, title: "Quit Dusk", action: #selector(quit), key: "q")
    }

    private func add(_ menu: NSMenu, title: String, action: Selector, key: String = "") {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
        item.target = self
    }

    @objc private func toggleEnabled() { model.enabled.toggle() }
    @objc private func selectEffect(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let style = EffectStyle(rawValue: raw) { model.effectStyle = style }
    }
    @objc private func preview() { model.preview() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc func showSettings() {
        if settingsWindow == nil {
            let content = NSHostingView(rootView: SettingsView(model: model))
            let size = content.fittingSize
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "Dusk"
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.contentView = content
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) { model.shutdown() }
}

if let index = CommandLine.arguments.firstIndex(of: "--render-effects"), CommandLine.arguments.count > index + 1 {
    do { try EffectContactSheet.write(to: URL(fileURLWithPath: CommandLine.arguments[index + 1])) }
    catch { fputs("\(error.localizedDescription)\n", stderr); exit(1) }
} else if CommandLine.arguments.contains("--probe") {
    // Read-only hardware verification; this path never creates a desktop overlay.
    let probe = HingeSensor { reading in
        if let angle = reading.angle {
            print("Hinge sensor available: \(Int(angle))°")
            exit(0)
        } else {
            fputs("\(reading.message)\n", stderr)
        }
    }
    probe.start()
    DispatchQueue.global().asyncAfter(deadline: .now() + 6) {
        fputs("No valid hinge reading within 6 seconds.\n", stderr)
        exit(1)
    }
    dispatchMain()
} else {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.run()
}
