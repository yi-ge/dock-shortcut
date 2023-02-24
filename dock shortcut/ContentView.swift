//
//  ContentView.swift
//  dock shortcut
//
//  Created by yige on 2022/12/25.
//

import SwiftUI
import LaunchAtLogin

struct ContentView: View {
    @AppStorage("preference_showMenuBarIcon") var showMenuBarIcon = true
    @AppStorage("preference_finderIsFirstApp") var finderIsFirstApp = true
    @AppStorage("preference_shotcutOption") var shotcutOption: String = ShotcutOption.option.rawValue
    var body: some View {
        TabView {
            VStack {
                Spacer()
                let settingLaunchTitle = NSLocalizedString("settingLaunchTitle", comment: "Launch:")
                let settingLaunchContent = NSLocalizedString("settingLaunchContent", comment: "Start at login")
                let settingMenuBarTitle = NSLocalizedString("settingMenuBarTitle", comment: "Menu bar:")
                let settingMenuBarContent = NSLocalizedString("settingMenuBarContent", comment: "Show menu bar icon")
                let settingOptionTitle = NSLocalizedString("settingOptionTitle", comment: "Option:")
                let settingOptionContent = NSLocalizedString("settingOptionContent", comment: "Finder is first application")
                let settingMenuBarNotice = NSLocalizedString("settingMenuBarNotice", comment: "setting menuBar notice")
                let settingOptionNotice = NSLocalizedString("settingOptionNotice", comment: "setting option notice")
                Form {
                    if #available(macOS 13.0, *) {
                        LabeledContent(settingLaunchTitle) {
                            LaunchAtLogin.Toggle {
                                Text(settingLaunchContent)
                            }
                        }
                        LabeledContent(settingMenuBarTitle) {
                            Toggle(settingMenuBarContent, isOn: $showMenuBarIcon).onChange(of: showMenuBarIcon) { value in
                                statusBarItem.isVisible = showMenuBarIcon
                            }
                        }
                        
                        Text(settingMenuBarNotice)
                            .allowsTightening(false)
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        LabeledContent(settingOptionTitle) {
                            Toggle(settingOptionContent, isOn: $finderIsFirstApp).onChange(of: finderIsFirstApp) { value in
                                globalFinderIsFirstApp = value
                            }
                        }
                        
                        Text(settingOptionNotice)
                            .allowsTightening(false)
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        LabeledHStack(settingLaunchTitle) {
                            LaunchAtLogin.Toggle {
                                Text(settingLaunchContent)
                            }
                        }
                        LabeledHStack(settingMenuBarTitle) {
                            Toggle(settingMenuBarContent, isOn: $showMenuBarIcon).onChange(of: showMenuBarIcon) { value in
                                statusBarItem.isVisible = showMenuBarIcon
                            }
                        }
                        
                        Text(settingMenuBarNotice)
                            .allowsTightening(false)
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        LabeledHStack(settingOptionTitle) {
                            Toggle(settingOptionContent, isOn: $finderIsFirstApp).onChange(of: finderIsFirstApp) { value in
                                globalFinderIsFirstApp = value
                            }
                        }
                        
                        Text(settingOptionNotice)
                            .allowsTightening(false)
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    
                    Picker(selection: $shotcutOption, label: Text(NSLocalizedString("settingHotKeyTitle", comment: "HotKey:"))) {
                        Text("Option + " + NSLocalizedString("settingHotKeyContent", comment: "Number")).tag(ShotcutOption.option.rawValue)
                        Text("Command + " + NSLocalizedString("settingHotKeyContent", comment: "Number")).tag(ShotcutOption.cmd.rawValue)
                        Text("Contrl + " + NSLocalizedString("settingHotKeyContent", comment: "Number")).tag(ShotcutOption.control.rawValue)
                        Text("Shift + " + NSLocalizedString("settingHotKeyContent", comment: "Number")).tag(ShotcutOption.shift.rawValue)
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: shotcutOption) { value in
                        for hotKeyRef in hotKeyRefs {
                            Hotkey.Unregister(hotKeyRef: hotKeyRef)
                        }
                        initHotKey(cocoaFlagsStr: ShotcutOption(rawValue: value) ?? ShotcutOption.option)
                    }
                }.padding()
                    .frame(minWidth: 200)
                
                Spacer()
                Button(NSLocalizedString("settingIssues", comment: "Issues")){
                    NSWorkspace.shared.open(URL(string:"https://github.com/yi-ge/dock-shortcut/issues")!)
                }
                
                Spacer()
                Spacer()
                Text("v" + getLocalVersion())
                Spacer()
                
                HStack {
                    Button(NSLocalizedString("quit", comment: "Quit") + " " + NSLocalizedString("CFBundleDisplayName", comment: "Dock Shortcut")){
                        NSApplication.shared.terminate(self)
                    }
                    
                    Button(NSLocalizedString("menuCheckUpdate", comment: "Check for update")){
                        Updater.share.check {}
                    }
                    
                    Button(NSLocalizedString("hiddenSetting", comment: "Hide Setting Window")){
                        NSApplication.shared.hide(self)
                    }
                }
            }
            .padding()
            .tabItem {
                Label(NSLocalizedString("setting", comment: "Setting"), systemImage: "sun.min")
            }
        }
        .frame(width: 440, height: 370)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
