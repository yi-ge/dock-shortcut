//
//  Hotkey.swift
//  dock shortcut
//
//  Created by yige on 2022/12/25.
//

import Carbon

enum ShortcutModifier: String {
    case control, cmd, shift, option, alpha

    var carbonFlags: UInt32 {
        switch self {
        case .control: return UInt32(controlKey)
        case .cmd: return UInt32(cmdKey)
        case .shift: return UInt32(shiftKey)
        case .option: return UInt32(optionKey)
        case .alpha: return UInt32(alphaLock)
        }
    }
}

final class Hotkey {
    private static let signature: OSType = 0x44534354 // DSCT
    private static let keyCodes = [
        kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5,
        kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9, kVK_ANSI_0,
    ]
    static var count: Int { keyCodes.count }

    private let onKey: @MainActor (Int) -> Void
    private var handler: EventHandlerRef?
    private var registrations: [EventHotKeyRef] = []

    init(onKey: @escaping @MainActor (Int) -> Void) {
        self.onKey = onKey
    }

    @MainActor
    func register(_ modifier: ShortcutModifier) -> Int {
        invalidate()
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, context in
                guard let event, let context else { return OSStatus(eventNotHandledErr) }
                var id = EventHotKeyID()
                let status = GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &id
                )
                let slot = Int(id.id)
                guard status == noErr, id.signature == Hotkey.signature, Hotkey.keyCodes.indices.contains(slot) else {
                    return OSStatus(eventNotHandledErr)
                }
                let callback = Unmanaged<Hotkey>.fromOpaque(context).takeUnretainedValue().onKey
                DispatchQueue.main.async { callback(slot) }
                return OSStatus(noErr)
            },
            1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler
        )
        guard result == noErr else { return 0 }

        for (slot, keyCode) in Self.keyCodes.enumerated() {
            var registration: EventHotKeyRef?
            let id = EventHotKeyID(signature: Self.signature, id: UInt32(slot))
            if RegisterEventHotKey(
                UInt32(keyCode), modifier.carbonFlags, id, GetApplicationEventTarget(), 0, &registration
            ) == noErr, let registration {
                registrations.append(registration)
            }
        }
        return registrations.count
    }

    @MainActor
    func invalidate() {
        for registration in registrations {
            UnregisterEventHotKey(registration)
        }
        registrations.removeAll()
        if let handler {
            RemoveEventHandler(handler)
            self.handler = nil
        }
    }
}
