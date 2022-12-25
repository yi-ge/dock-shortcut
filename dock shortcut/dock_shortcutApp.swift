//
//  dock_shortcutApp.swift
//  dock shortcut
//
//  Created by yige on 2022/12/25.
//

import SwiftUI

@main
struct dock_shortcutApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 470, idealWidth: 480, maxWidth: .infinity,
                                minHeight: 370, idealHeight: 380, maxHeight: .infinity,
                                alignment: .center)
        }
    }
}
