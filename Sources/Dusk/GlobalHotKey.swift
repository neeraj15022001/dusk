import Carbon

/// RegisterEventHotKey does not read keystrokes or require Accessibility access.
final class GlobalHotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) { self.action = action }

    func register() -> Bool {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let result = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            Unmanaged<GlobalHotKey>.fromOpaque(context).takeUnretainedValue().action()
            return noErr
        }, 1, &event, context, &handler)
        guard result == noErr else { return false }
        let id = EventHotKeyID(signature: 0x4455534B, id: 1)
        return RegisterEventHotKey(UInt32(kVK_ANSI_K), UInt32(controlKey | optionKey | cmdKey),
                                   id, GetApplicationEventTarget(), 0, &reference) == noErr
    }

    deinit {
        if let reference { UnregisterEventHotKey(reference) }
        if let handler { RemoveEventHandler(handler) }
    }
}
