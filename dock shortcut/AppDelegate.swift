//
//  AppDelegate.swift
//  dock shortcut
//
//  Created by yige on 2022/12/23.
//
import Foundation
import AppKit
import SwiftUI
import Cocoa
import Carbon
import Foundation
import SystemConfiguration

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

enum DockSection: String {
    case persistentApps = "persistent-apps"
    case recentApps = "recent-apps"
    case persistentOthers = "persistent-others"
}

// Status Bar Item...
var statusBarItem: NSStatusItem!

class AppDelegate: NSObject, NSApplicationDelegate {
    // Menu View...
    let menuView = ContentView();
    
    let dockDomain = "com.apple.dock"
    let sections : [DockSection] = [.persistentApps, .recentApps, .persistentOthers]

    var dockItems = [DockSection:[DockTile]]()
    var plist = [String:AnyObject]()
    var window: NSWindow?
    
    func applicationDidFinishLaunching(_: Notification) {
        // Close main app window
        window = NSApplication.shared.windows.first
        window?.title = NSLocalizedString("CFBundleDisplayName", comment: "Dock Shortcut")
        
        
        statusBarItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength)
        
        if let showMenuBarIcon = UserDefaults.standard.string(forKey: "preference_showMenuBarIcon") {
            if window != nil && showMenuBarIcon == "1" {
                window?.close()
            }
            
            if showMenuBarIcon == "0" {
                statusBarItem.isVisible = false
            }
        } else if window != nil {
            window?.close()
        }

        let statusBarMenu = NSMenu(title: "Status Bar Menu")
        statusBarItem.menu = statusBarMenu

        statusBarMenu.addItem(
            withTitle: NSLocalizedString("setting", comment: "Setting") + "...",
            action: #selector(AppDelegate.setting),
            keyEquivalent: "")
        
        statusBarMenu.addItem(
            withTitle: NSLocalizedString("menuCheckUpdate", comment: "Check for update"),
            action: #selector(AppDelegate.checkUpdate),
            keyEquivalent: "")
        
        statusBarMenu.addItem(.separator())
        
        statusBarMenu.addItem(
            withTitle: NSLocalizedString("quit", comment: "Quit"),
            action: #selector(AppDelegate.exitApp),
            keyEquivalent: "")
        

        // Safe Check if status Button is Available or not...
        if let MenuButton = statusBarItem?.button {
//            MenuButton.image = NSImage(systemSymbolName: "icloud.and.arrow.up.fill", accessibilityDescription: nil)
            MenuButton.image = NSImage(imageLiteralResourceName: "DockIcon")
            MenuButton.image!.size = NSSize(width: 18, height: 18)
            MenuButton.imagePosition = .imageLeft
        }
        

        

        func openAPP(bundleIdentifier: String) {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }

            let path = "/bin"
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.arguments = [path]
            NSWorkspace.shared.openApplication(at: url,
                                               configuration: configuration,
                                               completionHandler: nil)
        }

        func printOptional(_ item: String?) -> String {
            item != nil ? item! : ""
        }

        func printList() {
            forEach() {tile in
                print("\(printOptional(tile.label))\t\(printOptional(tile.url))\t\(printOptional(tile.bundleIdentifier))")
            }
        }

        func forEach(closure: (DockTile) -> Void) {
            for section in sections {
                if let items = dockItems[section] {
                    for dockItem in items {
                        closure(dockItem)
                    }
                }
            }
        }

        for section in sections {
            if let value = CFPreferencesCopyAppValue(section.rawValue as CFString, dockDomain as CFString) as? [[String: AnyObject]] {
                dockItems[section] = value.map({item in
                    DockTile(dict: item, section: section)
                })
            }
        }

        printList()


//        openAPP(bundleIdentifier: "com.apple.MobileSMS")

        let backgroundQueue = DispatchQueue(label: "com.app.queue", qos: .background)
        backgroundQueue.async {
            print("Run on background thread")
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

            var hotKeyRef: EventHotKeyRef?
            let modifierFlags: UInt32 =
              getCarbonFlagsFromCocoaFlags(cocoaFlags: NSEvent.ModifierFlags.option)

            let keyCode = kVK_ANSI_R
            var gMyHotKeyID = EventHotKeyID()

            gMyHotKeyID.id = UInt32(keyCode)

            // Not sure what "swat" vs "htk1" do.
            gMyHotKeyID.signature = OSType("swat".fourCharCodeValue)
            // gMyHotKeyID.signature = OSType("htk1".fourCharCodeValue)

            var eventType = EventTypeSpec()
            eventType.eventClass = OSType(kEventClassKeyboard)
            eventType.eventKind = OSType(kEventHotKeyReleased)

            // Install handler.
            InstallEventHandler(GetApplicationEventTarget(), {
              (nextHanlder, theEvent, userData) -> OSStatus in
              // var hkCom = EventHotKeyID()

              // GetEventParameter(theEvent,
              //                   EventParamName(kEventParamDirectObject),
              //                   EventParamType(typeEventHotKeyID),
              //                   nil,
              //                   MemoryLayout<EventHotKeyID>.size,
              //                   nil,
              //                   &hkCom)

              NSLog("Command + R Released!")

              return noErr
              /// Check that hkCom in indeed your hotkey ID and handle it.
            }, 1, &eventType, nil, nil)

            // Register hotkey.
            let status = RegisterEventHotKey(UInt32(keyCode),
                                             modifierFlags,
                                             gMyHotKeyID,
                                             GetApplicationEventTarget(),
                                             0,
                                             &hotKeyRef)
            assert(status == noErr)
        }


        print("Hello, World!")
    }

    
    @objc func setting() {
        if window != nil {
            window?.makeKeyAndOrderFront(nil)
            let controller = NSWindowController(window: window)
            controller.showWindow(self)
        }
    }


    @objc func checkUpdate() {
        Updater.share.check {}
    }
    
    @objc func exitApp() {
        exit(0);
    }
}
