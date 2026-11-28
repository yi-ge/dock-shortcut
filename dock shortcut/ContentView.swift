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
    static let preferredSize = NSSize(width: 556, height: 448)

    @AppStorage("preference_showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("preference_finderIsFirstApp") private var finderIsFirstApp = true
    @AppStorage("preference_shotcutOption") private var shortcutModifier = ShortcutModifier.option.rawValue

    var onMenuBarVisibilityChange: (Bool) -> Void = { _ in }
    var onShortcutModifierChange: (String) -> Void = { _ in }
    var onHide: () -> Void = {}

    private var selectedModifier: ShortcutModifier {
        ShortcutModifier(rawValue: shortcutModifier) ?? .option
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    shortcutSettings
                    generalSettings
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
            footer
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: shortcutModifier, perform: onShortcutModifierChange)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("CFBundleDisplayName")
                    .font(.system(size: 24, weight: .semibold))
                Text("settingsDescription")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var shortcutSettings: some View {
        settingsGroup("shortcutSettings", systemImage: "keyboard") {
            SettingsRow("settingHotKeyTitle", detail: Text("shortcutNumberHint")) {
                modifierPicker
            }
            Divider().padding(.horizontal, 14)
            SettingsRow("settingOptionContent", detail: Text(verbatim: finderShortcutDescription)) {
                Toggle("settingOptionContent", isOn: $finderIsFirstApp)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle())
            }
        }
    }

    @ViewBuilder
    private var modifierPicker: some View {
        let selection = Binding(
            get: { selectedModifier },
            set: { shortcutModifier = $0.rawValue }
        )
        let modifiers: [ShortcutModifier] = [.option, .cmd, .control, .shift]

        if selectedModifier == .alpha {
            Picker("settingHotKeyTitle", selection: selection) {
                ForEach(modifiers + [.alpha], id: \.self) { modifier in
                    modifierLabel(modifier)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        } else {
            Picker("settingHotKeyTitle", selection: selection) {
                ForEach(modifiers, id: \.self) { modifier in
                    modifierLabel(modifier)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 335)
        }
    }

    private func modifierLabel(_ modifier: ShortcutModifier) -> some View {
        Text(verbatim: modifier.settingsLabel)
            .tag(modifier)
    }

    private var finderShortcutDescription: String {
        let format = finderIsFirstApp
            ? NSLocalizedString("finderShortcutOn", comment: "Finder occupies the first shortcut slot")
            : NSLocalizedString("finderShortcutOff", comment: "The first pinned application occupies the first shortcut slot")
        return String.localizedStringWithFormat(format, selectedModifier.settingsLabel)
    }

    private var generalSettings: some View {
        settingsGroup("generalSettings", systemImage: "gearshape") {
            loginItem
            Divider().padding(.horizontal, 14)
            SettingsRow("settingMenuBarContent", detail: Text("settingMenuBarNotice")) {
                Toggle("settingMenuBarContent", isOn: $showMenuBarIcon)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: showMenuBarIcon, perform: onMenuBarVisibilityChange)
            }
        }
    }

    @ViewBuilder
    private var loginItem: some View {
        if #available(macOS 13.0, *), let bundleIdentifier = Bundle.main.bundleIdentifier {
            LoginItemToggle(service: .loginItem(identifier: bundleIdentifier + "-LaunchAtLoginHelper"))
        } else {
            SettingsRow("settingLaunchContent") {
                LaunchAtLogin.Toggle { Text("settingLaunchContent") }
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle())
            }
        }
    }

    private func settingsGroup<Content: View>(
        _ title: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0, content: content)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10))
                        .allowsHitTesting(false)
                )
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Text("v" + getLocalVersion())
                .foregroundColor(.secondary)
            Link("settingIssues", destination: URL(string: "https://github.com/yi-ge/dock-shortcut/issues")!)
            Spacer()
            Button("quit") { NSApp.terminate(nil) }
            Button("menuCheckUpdate") { Updater.shared.check() }
            Button("settingsDone", action: onHide)
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 13)
    }
}

private struct SettingsRow<Control: View>: View {
    let title: LocalizedStringKey
    let detail: Text?
    @ViewBuilder let control: () -> Control

    init(_ title: LocalizedStringKey, detail: Text? = nil, @ViewBuilder control: @escaping () -> Control) {
        self.title = title
        self.detail = detail
        self.control = control
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.medium)
                    .accessibilityHidden(true)
                if let detail {
                    detail
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            control()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private extension ShortcutModifier {
    var settingsLabel: String {
        switch self {
        case .option: return "⌥ Option"
        case .cmd: return "⌘ Command"
        case .control: return "⌃ Control"
        case .shift: return "⇧ Shift"
        case .alpha: return "⇪ Caps Lock"
        }
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
        VStack(alignment: .leading, spacing: 0) {
            SettingsRow("settingLaunchContent") {
                Toggle("settingLaunchContent", isOn: Binding(
                    get: { isRegistered(status) },
                    set: updateRegistration
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle())
            }
            if status == .requiresApproval || error != nil {
                VStack(alignment: .leading, spacing: 6) {
                    if status == .requiresApproval {
                        Text("loginApprovalRequired")
                        Button("openLoginItemSettings") {
                            SMAppService.openSystemSettingsLoginItems()
                        }
                    }
                    if let error {
                        Label(error, systemImage: "exclamationmark.circle")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding([.horizontal, .bottom], 14)
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
            .frame(width: ContentView.preferredSize.width, height: ContentView.preferredSize.height)
    }
}
