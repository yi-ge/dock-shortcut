//
//  ContentView.swift
//  dock shortcut
//
//  Created by yige on 2022/12/25.
//

import AppKit
import LaunchAtLogin
import ServiceManagement
import SwiftUI

struct ContentView: View {
    @AppStorage("preference_showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("preference_finderIsFirstApp") private var finderIsFirstApp = true
    @AppStorage("preference_shotcutOption") private var shortcutModifier = ShortcutModifier.option.rawValue

    var onMenuBarVisibilityChange: (Bool) -> Void = { _ in }
    var onShortcutModifierChange: (String) -> Void = { _ in }
    var onHide: () -> Void = {}

    var body: some View {
        TabView {
            VStack {
                Form {
                    settingRow(NSLocalizedString("settingLaunchTitle", comment: "Launch:")) {
                        loginItem
                    }
                    settingRow(NSLocalizedString("settingMenuBarTitle", comment: "Menu bar:")) {
                        Toggle(NSLocalizedString("settingMenuBarContent", comment: "Show menu bar icon"), isOn: $showMenuBarIcon)
                            .onChange(of: showMenuBarIcon, perform: onMenuBarVisibilityChange)
                    }
                    notice(NSLocalizedString("settingMenuBarNotice", comment: "Recover settings when the icon is hidden"))
                    settingRow(NSLocalizedString("settingOptionTitle", comment: "Option:")) {
                        Toggle(NSLocalizedString("settingOptionContent", comment: "Finder is the first app"), isOn: $finderIsFirstApp)
                    }
                    notice(NSLocalizedString("settingOptionNotice", comment: "Finder shortcut behavior"))
                    Picker(
                        NSLocalizedString("settingHotKeyTitle", comment: "Hotkey:"),
                        selection: $shortcutModifier
                    ) {
                        let number = NSLocalizedString("settingHotKeyContent", comment: "Number")
                        Text("Option + \(number)").tag(ShortcutModifier.option.rawValue)
                        Text("Command + \(number)").tag(ShortcutModifier.cmd.rawValue)
                        Text("Control + \(number)").tag(ShortcutModifier.control.rawValue)
                        Text("Shift + \(number)").tag(ShortcutModifier.shift.rawValue)
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: shortcutModifier, perform: onShortcutModifierChange)
                }
                .padding()

                Spacer()
                Link(
                    NSLocalizedString("settingIssues", comment: "Issues"),
                    destination: URL(string: "https://github.com/yi-ge/dock-shortcut/issues")!
                )
                Text("v" + getLocalVersion())
                Spacer()
                HStack {
                    Button(NSLocalizedString("quit", comment: "Quit")) { NSApp.terminate(nil) }
                    Button(NSLocalizedString("menuCheckUpdate", comment: "Check for update")) { Updater.shared.check() }
                    Button(NSLocalizedString("hiddenSetting", comment: "Hide settings window"), action: onHide)
                }
            }
            .padding()
            .tabItem {
                Label(NSLocalizedString("setting", comment: "Settings"), systemImage: "sun.min")
            }
        }
        .frame(width: 480, height: 460)
    }

    @ViewBuilder
    private var loginItem: some View {
        if #available(macOS 13.0, *), let bundleIdentifier = Bundle.main.bundleIdentifier {
            LoginItemToggle(service: .loginItem(identifier: bundleIdentifier + "-LaunchAtLoginHelper"))
        } else {
            LaunchAtLogin.Toggle {
                Text(NSLocalizedString("settingLaunchContent", comment: "Start at login"))
            }
        }
    }

    @ViewBuilder
    private func settingRow<Content: View>(_ label: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        if #available(macOS 13.0, *) {
            LabeledContent(label, content: content)
        } else {
            LabeledHStack(label, content: content)
        }
    }

    private func notice(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12, weight: .light))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

@available(macOS 13.0, *)
private struct LoginItemToggle: View {
    let service: SMAppService
    // The previous release used LaunchAtLogin, which registered the main app on macOS 13 and later.
    private let previousService = SMAppService.mainApp
    @State private var status: SMAppService.Status = .notRegistered
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(
                NSLocalizedString("settingLaunchContent", comment: "Start at login"),
                isOn: Binding(
                    get: { isRegistered(status) },
                    set: updateRegistration
                )
            )
            if status == .requiresApproval {
                Button(NSLocalizedString("openLoginItemSettings", comment: "Open login item settings")) {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear(perform: refreshStatus)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshStatus()
        }
    }

    private func updateRegistration(_ enabled: Bool) {
        error = nil
        if enabled {
            do {
                try service.register()
            } catch {
                self.error = error.localizedDescription
            }
        } else {
            for item in [service, previousService] where isRegistered(item.status) {
                do {
                    try item.unregister()
                } catch {
                    self.error = error.localizedDescription
                }
            }
        }
        refreshStatus()
    }

    private func refreshStatus() {
        let current = service.status
        let previous = previousService.status
        if current == .enabled || previous == .enabled {
            status = .enabled
        } else if previous == .requiresApproval {
            status = .requiresApproval
        } else {
            status = current
        }
    }

    private func isRegistered(_ status: SMAppService.Status) -> Bool {
        status == .enabled || status == .requiresApproval
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
