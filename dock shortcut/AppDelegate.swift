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

enum DockSection: String {
    case persistentApps = "persistent-apps"
    case recentApps = "recent-apps"
    case persistentOthers = "persistent-others"
}

enum ShotcutOption: String {
    case control, cmd, shift, option, alpha
}

// Status Bar Item...
var statusBarItem: NSStatusItem!

let sections : [DockSection] = [.persistentApps, .recentApps, .persistentOthers]

var dockItems = [DockSection:[DockTile]]()

var hotKeyRefs = [EventHotKeyRef]()

var globalFinderIsFirstApp: Bool = true

let numberAnsi = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9, kVK_ANSI_0]

var lastOpen = ""

func openAPP(bundleIdentifier: String) {
    if (lastOpen == bundleIdentifier && NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifier) {
        NSWorkspace.shared.frontmostApplication?.hide()
        lastOpen = ""
    } else {
        lastOpen = bundleIdentifier
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }
        
//        let path = "/bin"
        let configuration = NSWorkspace.OpenConfiguration()
//        configuration.arguments = [path]
        NSWorkspace.shared.openApplication(at: url,
                                           configuration: configuration,
                                           completionHandler: nil)
    }
}

func initHotKey(cocoaFlagsStr: ShotcutOption) {
    var cocoaFlags = NSEvent.ModifierFlags.option
    
    switch cocoaFlagsStr {
    case .control:
        cocoaFlags = NSEvent.ModifierFlags.control
    case .cmd:
        cocoaFlags = NSEvent.ModifierFlags.command
    case .shift:
        cocoaFlags = NSEvent.ModifierFlags.shift
    case .option:
        cocoaFlags = NSEvent.ModifierFlags.option
    case .alpha:
        cocoaFlags = NSEvent.ModifierFlags.capsLock
    }
    let backgroundQueue = DispatchQueue(label: "com.app.queue", qos: .background)
    backgroundQueue.async {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyReleased)
        
        // Install handler.
        InstallEventHandler(GetApplicationEventTarget(), {
            (nextHanlder, theEvent, userData) -> OSStatus in
            var hkCom = EventHotKeyID()
            
            GetEventParameter(theEvent,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hkCom)
            
            if var index = numberAnsi.firstIndex(of: Int(hkCom.id)) {
                if globalFinderIsFirstApp {
                    if index == 0 {
                        openAPP(bundleIdentifier: "com.apple.finder")
                        return noErr
                    } else {
                        index -= 1
                    }
                }
                
                if let bundleIdentifier = dockItems[.persistentApps]?[index].bundleIdentifier {
                    openAPP(bundleIdentifier: bundleIdentifier)
                }
            }
            
            
            return noErr
            /// Check that hkCom in indeed your hotkey ID and handle it.
        }, 1, &eventType, nil, nil)
        
        for index in 0...9 {
            if let hotKeyRef = Hotkey.register(keyCode: numberAnsi[index], cocoaFlags: cocoaFlags) {
                hotKeyRefs.append(hotKeyRef)
            }
        }
        NSLog("Run on background thread")
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // Menu View...
    let menuView = ContentView();
    
    let dockDomain = "com.apple.dock"
    
    var plist = [String:AnyObject]()
    var window: NSWindow?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 获取应用程序启动选项
        guard let options = aNotification.userInfo else {
            // 如果无法获取启动选项，则假定应用程序是从用户主动点击启动的
            print("Application launched by user.")
            return
        }
        
        // 检查启动选项中是否包含 NSApplicationLaunchUserNotificationKey 键
        if let isUserNotification = options[NSApplication.launchUserNotificationUserInfoKey] as? Bool, isUserNotification {
            print("Application launched from a user notification.")
            window?.close() // Close main app window
        } else {
            print("Application launched by user.")
            window = NSApplication.shared.windows.first
            window?.title = NSLocalizedString("CFBundleDisplayName", comment: "Dock Shortcut")
            
            
            statusBarItem = NSStatusBar.system.statusItem(
                withLength: NSStatusItem.squareLength)
            
            if let showMenuBarIcon = UserDefaults.standard.string(forKey: "preference_showMenuBarIcon") {
                if showMenuBarIcon == "0" {
                    statusBarItem.isVisible = false
                }
                
                if window != nil {
                    window?.close() // Close main app window
                }
            } else if window != nil {
                window?.close() // Close main app window
            }
        }
        
        if let finderIsFirstApp = UserDefaults.standard.string(forKey: "preference_finderIsFirstApp") {
            globalFinderIsFirstApp = finderIsFirstApp == "1"
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
            MenuButton.image = NSImage(imageLiteralResourceName: "DockIcon")
            MenuButton.image!.size = NSSize(width: 18, height: 18)
            MenuButton.imagePosition = .imageLeft
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
        
        if let shotcutOption = UserDefaults.standard.string(forKey: "preference_shotcutOption") {
            initHotKey(cocoaFlagsStr: ShotcutOption(rawValue: shotcutOption) ?? ShotcutOption.option)
        } else {
            initHotKey(cocoaFlagsStr: ShotcutOption.option)
        }
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
