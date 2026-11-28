//
//  AppDelegate.swift
//  dock shortcut
//
//  Created by yige on 2022/12/23.
//

import AppKit
import OSLog
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.yige.dock-shortcut", category: "app")
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var lastOpenedBundleIdentifier: String?
    private lazy var hotkeys = Hotkey { [weak self] slot in
        self?.openApplication(at: slot)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        item.isVisible = preference("preference_showMenuBarIcon", default: true)
        if let image = NSImage(named: "DockIcon") {
            image.size = NSSize(width: 18, height: 18)
            item.button?.image = image
        }
        item.button?.setAccessibilityLabel("Dock Shortcut")

        let menu = NSMenu()
        for (title, action) in [
            (NSLocalizedString("setting", comment: "Settings") + "…", #selector(showSettings)),
            (NSLocalizedString("menuCheckUpdate", comment: "Check for update"), #selector(checkUpdate)),
        ] {
            menu.addItem(withTitle: title, action: action, keyEquivalent: "").target = self
        }
        menu.addItem(.separator())
        menu.addItem(
            withTitle: NSLocalizedString("quit", comment: "Quit"),
            action: #selector(quit),
            keyEquivalent: ""
        ).target = self
        item.menu = menu

        let savedModifier = UserDefaults.standard.string(forKey: "preference_shotcutOption")
        registerHotkeys(savedModifier, reportConflicts: false)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeys.invalidate()
    }

    private func preference(_ key: String, default value: Bool) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? value : defaults.bool(forKey: key)
    }

    private func registerHotkeys(_ value: String?, reportConflicts: Bool) {
        let modifier = value.flatMap(ShortcutModifier.init(rawValue:)) ?? .option
        let count = hotkeys.register(modifier)
        logger.info("Registered \(count, privacy: .public) of \(Hotkey.count, privacy: .public) Dock shortcuts")
        if reportConflicts && count != Hotkey.count {
            tipInfo(
                withTitle: NSLocalizedString("warning", comment: "Warning"),
                withMessage: NSLocalizedString("registerHotKeyErr", comment: "Shortcut conflict")
            )
        }
    }

    private func openApplication(at slot: Int) {
        let finderFirst = preference("preference_finderIsFirstApp", default: true)
        guard let identifier = DockTile.applicationIdentifier(at: slot, finderFirst: finderFirst) else { return }

        let workspace = NSWorkspace.shared
        if lastOpenedBundleIdentifier == identifier,
           let frontmost = workspace.frontmostApplication,
           frontmost.bundleIdentifier == identifier {
            if frontmost.hide() { lastOpenedBundleIdentifier = nil }
            return
        }

        guard let url = workspace.urlForApplication(withBundleIdentifier: identifier) else { return }
        lastOpenedBundleIdentifier = identifier
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        workspace.openApplication(at: url, configuration: configuration, completionHandler: nil)
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let content = ContentView(
                onMenuBarVisibilityChange: { [weak self] in self?.statusItem?.isVisible = $0 },
                onShortcutModifierChange: { [weak self] in self?.registerHotkeys($0, reportConflicts: true) },
                onHide: { [weak self] in self?.settingsWindow?.orderOut(nil) }
            )
            let window = NSWindow(contentViewController: NSHostingController(rootView: content))
            window.title = NSLocalizedString("setting", comment: "Settings")
            window.setContentSize(ContentView.preferredSize)
            window.styleMask.remove(.resizable)
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func checkUpdate() {
        Updater.shared.check()
    }

    @objc private func quit() {
        NSApp.terminate(self)
    }
}
