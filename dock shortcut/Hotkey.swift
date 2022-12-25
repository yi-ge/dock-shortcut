//
//  Hotkey.swift
//  dock shortcut
//
//  Created by yige on 2022/12/25.
//

import Carbon
import AppKit

extension String {
    /// This converts string to UInt as a fourCharCode
    public var fourCharCodeValue: Int {
        var result: Int = 0
        if let data = self.data(using: String.Encoding.macOSRoman) {
            data.withUnsafeBytes({ (rawBytes) in
                let bytes = rawBytes.bindMemory(to: UInt8.self)
                for i in 0 ..< data.count {
                    result = result << 8 + Int(bytes[i])
                }
            })
        }
        return result
    }
}

class Hotkey {
    static
    func getCarbonFlagsFromCocoaFlags(cocoaFlags: NSEvent.ModifierFlags) -> UInt32 {
        let flags = cocoaFlags.rawValue
        var newFlags: Int = 0
        
        if ((flags & NSEvent.ModifierFlags.control.rawValue) > 0) {
            newFlags |= controlKey
        }
        
        if ((flags & NSEvent.ModifierFlags.command.rawValue) > 0) {
            newFlags |= cmdKey
        }
        
        if ((flags & NSEvent.ModifierFlags.shift.rawValue) > 0) {
            newFlags |= shiftKey;
        }
        
        if ((flags & NSEvent.ModifierFlags.option.rawValue) > 0) {
            newFlags |= optionKey
        }
        
        if ((flags & NSEvent.ModifierFlags.capsLock.rawValue) > 0) {
            newFlags |= alphaLock
        }
        
        return UInt32(newFlags);
    }
    
    static func register(keyCode: Int, cocoaFlags: NSEvent.ModifierFlags) -> EventHotKeyRef! {
        var hotKeyRef: EventHotKeyRef?
        let modifierFlags: UInt32 =
        getCarbonFlagsFromCocoaFlags(cocoaFlags: cocoaFlags)
        
        var gMyHotKeyID = EventHotKeyID()
        
        gMyHotKeyID.id = UInt32(keyCode)
        
        // Not sure what "swat" vs "htk1" do.
        gMyHotKeyID.signature = OSType("swat".fourCharCodeValue)
        // gMyHotKeyID.signature = OSType("htk1".fourCharCodeValue)
        
        // Register hotkey.
        let status = RegisterEventHotKey(UInt32(keyCode),
                                         modifierFlags,
                                         gMyHotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)
        
        if status != noErr {
            tipInfo(withTitle: NSLocalizedString("warning", comment: "Warning"),
                    withMessage: NSLocalizedString("registerHotKeyErr", comment: "Hotkey conflict, failed to register shortcut keys"))
        }

        return hotKeyRef
    }
    
    static func Unregister(hotKeyRef: EventHotKeyRef) {
        UnregisterEventHotKey(hotKeyRef);
    }
}
