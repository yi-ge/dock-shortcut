//  Fork from https://github.com/kcrawford/dockutil/blob/main/dockutil/DockTile.swift
//  Created by Kyle Crawford on 6/18/20.
//  Copyright © 2022 Kyle Crawford. All rights reserved.

import Foundation

enum DockTile {
    static func applicationIdentifier(at slot: Int, finderFirst: Bool) -> String? {
        if finderFirst && slot == 0 { return "com.apple.finder" }

        let index = finderFirst ? slot - 1 : slot
        let domain = "com.apple.dock" as CFString
        CFPreferencesAppSynchronize(domain)
        let tiles = CFPreferencesCopyAppValue("persistent-apps" as CFString, domain) as? [[String: Any]] ?? []
        guard tiles.indices.contains(index),
              let data = tiles[index]["tile-data"] as? [String: Any],
              let identifier = data["bundle-identifier"] as? String,
              !identifier.isEmpty else { return nil }
        return identifier
    }
}
