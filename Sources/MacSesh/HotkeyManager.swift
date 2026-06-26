import Carbon.HIToolbox
import Foundation

// Carbon event callbacks are C function pointers and cannot capture Swift context.
// We store handler closures in a global dictionary keyed by hotkey ID instead.
nonisolated(unsafe) private var hotkeyHandlers: [UInt32: () -> Void] = [:]
nonisolated(unsafe) private var carbonEventHandler: EventHandlerRef?
nonisolated(unsafe) private var nextHotkeyID: UInt32 = 1

private let carbonCallback: EventHandlerUPP = { _, event, _ -> OSStatus in
    guard let event else { return OSStatus(eventNotHandledErr) }
    var hkID = EventHotKeyID()
    GetEventParameter(event, EventParamName(kEventParamDirectObject),
                      EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
    let id = hkID.id
    DispatchQueue.main.async { hotkeyHandlers[id]?() }
    return noErr
}

/// Registers a global hotkey using Carbon's RegisterEventHotKey.
///
/// Unlike NSEvent monitors, Carbon hotkeys do not require Accessibility or
/// Input Monitoring permission — they work as soon as the app is running.
///
/// - Parameters:
///   - keyCode: A Carbon virtual key code (e.g. kVK_ANSI_S = 1, kVK_ANSI_D = 2).
///   - modifiers: Carbon modifier mask (e.g. cmdKey | shiftKey | optionKey | controlKey).
///   - handler: Called on the main thread when the hotkey fires.
func registerGlobalHotkey(keyCode: Int, modifiers: Int, handler: @escaping () -> Void) {
    if carbonEventHandler == nil {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetApplicationEventTarget(), carbonCallback,
                            1, &spec, nil, &carbonEventHandler)
    }

    let id = nextHotkeyID
    nextHotkeyID += 1
    hotkeyHandlers[id] = handler

    let hkID = EventHotKeyID(signature: 0x4D535348 /* "MSSH" */, id: id)
    var ref: EventHotKeyRef?
    RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), hkID,
                        GetApplicationEventTarget(), 0, &ref)
}
