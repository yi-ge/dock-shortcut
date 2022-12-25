//
//  Utils.swift
//  dock shortcut
//
//  Created by yige on 2022/12/25.
//

import Foundation
import AppKit

func getLocalVersion() -> String {
    var localVersion:String = ""

    if let v:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String{
        localVersion = v
    }

    return localVersion
}

func tipInfo(withTitle: String, withMessage: String) {
    let alert = NSAlert()
    alert.messageText = withTitle
    alert.informativeText = withMessage
    alert.addButton(withTitle: NSLocalizedString("button-ok", comment: ""))
    alert.window.titlebarAppearsTransparent = true
    alert.runModal()
}

func tipInfo(withTitle title: String, withMessage message: String, oKButtonTitle: String, cancelButtonTitle: String, okHandler:(()-> Void)) {
    let alert = NSAlert()
    alert.alertStyle = NSAlert.Style.informational
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: oKButtonTitle)
    alert.addButton(withTitle: cancelButtonTitle)
    alert.window.titlebarAppearsTransparent = true
    if alert.runModal() == .alertFirstButtonReturn {
        okHandler()
    }
}
