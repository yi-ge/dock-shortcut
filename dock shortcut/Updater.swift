//  Fork from: https://github.com/smslit/timeGO/blob/master/timeGO/TimeGoUpdater.swift
//  Updater.swift
//  dock shortcut

import Cocoa

@MainActor
final class Updater {
    static let shared = Updater()
    private let apiURL = URL(string: "https://api.github.com/repos/yi-ge/dock-shortcut/releases/latest")!
    private let releasesURL = URL(string: "https://github.com/yi-ge/dock-shortcut/releases")!

    private struct Release: Decodable {
        let tagName: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
        }
    }

    func check() {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, response, _ in
            let response = response as? HTTPURLResponse
            let status = response?.statusCode
            let rateLimited = status == 429 || (status == 403 && (
                response?.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0" ||
                response?.value(forHTTPHeaderField: "Retry-After") != nil
            ))
            let release = status == 200 ? data.flatMap { try? JSONDecoder().decode(Release.self, from: $0) } : nil
            DispatchQueue.main.async {
                if rateLimited {
                    self.checkLatestReleasePage()
                } else {
                    self.showResult(tag: release?.tagName)
                }
            }
        }.resume()
    }

    private func checkLatestReleasePage() {
        let tagDirectory = releasesURL.appendingPathComponent("tag", isDirectory: true)
        var request = URLRequest(url: releasesURL.appendingPathComponent("latest"))
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { _, response, _ in
            let response = response as? HTTPURLResponse
            let url = response?.url
            let tag = response?.statusCode == 200 && url?.deletingLastPathComponent() == tagDirectory
                ? url?.lastPathComponent : nil
            DispatchQueue.main.async {
                self.showResult(tag: tag)
            }
        }.resume()
    }

    private func showResult(tag: String?) {
        let title = NSLocalizedString("menuCheckUpdate", comment: "Check for update")
        guard let tag, tag.hasPrefix("v"),
              let latest = Self.versionComponents(String(tag.dropFirst())),
              let current = Self.versionComponents(getLocalVersion()) else {
            tipInfo(withTitle: title, withMessage: NSLocalizedString("networkError", comment: "Connection error"))
            return
        }

        guard latest > current else {
            tipInfo(withTitle: title, withMessage: NSLocalizedString("updateNone", comment: "No updates"))
            return
        }

        tipInfo(
            withTitle: title,
            withMessage: NSLocalizedString("checkedUpdateNewVersion", comment: "Found a new version") + " \(tag)",
            oKButtonTitle: NSLocalizedString("goToDownload", comment: "Download"),
            cancelButtonTitle: NSLocalizedString("ignore", comment: "Ignore")
        ) {
            NSWorkspace.shared.open(releasesURL.appendingPathComponent("tag").appendingPathComponent(tag))
        }
    }

    nonisolated static func versionComponents(_ value: String) -> (Int, Int, Int)? {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        let components = parts.compactMap { part -> Int? in
            guard !part.isEmpty, part.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
            return Int(part)
        }
        guard (2...3).contains(parts.count), components.count == parts.count else { return nil }
        return (components[0], components[1], components.count == 3 ? components[2] : 0)
    }
}
