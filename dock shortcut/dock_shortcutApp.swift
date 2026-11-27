//
//  dock_shortcutApp.swift
//  dock shortcut
//
//  Created by yige on 2022/12/25.
//

import AppKit

@main
struct DockShortcutApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}
