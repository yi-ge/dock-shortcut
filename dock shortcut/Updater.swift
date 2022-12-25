//  Fork from: https://github.com/smslit/timeGO/blob/master/timeGO/TimeGoUpdater.swift
//  Updater.swift
//  dock shortcut

import Cocoa


class Updater {
    
    private let url: URL?
    private let user: String
    
    static let share = Updater(user: "yi-ge")
    
    init(user: String) {
        self.user = user
        let proName = "dock-shortcut"// Bundle.main.infoDictionary!["CFBundleExecutable"]!
        self.url = URL(string: "https://raw.githubusercontent.com/\(user)/\(proName)/master/\(proName)/Info.plist")
    }
    
    func check(callback: @escaping (()->Void)) {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: self.url!) { (data, response, error) in
            self.checkUpdateRequestSuccess(data: data, response: response, error: error, callback: callback)
        }
        task.resume()
    }
    
    private func checkUpdateRequestSuccess(data:Data?, response:URLResponse?, error:Error?, callback: @escaping (()->Void)) -> Void {
        DispatchQueue.main.async {
            callback()
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    // :TODO 加日志
                    tipInfo(withTitle: NSLocalizedString("menuCheckUpdate", comment: "Check for update"),
                            withMessage: NSLocalizedString("networkError", comment: "Connection Invalid"))
                    return
                }
                var propertyListForamt = PropertyListSerialization.PropertyListFormat.xml
                do {
                    let infoPlist = try PropertyListSerialization.propertyList(from: data!, options: PropertyListSerialization.ReadOptions.mutableContainersAndLeaves, format: &propertyListForamt) as! [String: AnyObject]
                    let latestVersion = infoPlist["CFBundleShortVersionString"] as! String
                    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
                    if latestVersion == appVersion {
                        tipInfo(withTitle: NSLocalizedString("menuCheckUpdate", comment: "Check for update"),
                                withMessage: NSLocalizedString("updateNone", comment: "No updates"))
                        return
                    }
                    
                    tipInfo(withTitle: NSLocalizedString("menuCheckUpdate", comment: "Check for update"),
                            withMessage: NSLocalizedString("checkedUpdateNewVersion", comment: "Found new version") + " v\(latestVersion)",
                        oKButtonTitle: NSLocalizedString("goToDownload", comment: "Download"),
                        cancelButtonTitle: NSLocalizedString("ignore", comment: "Ignore")) {
                            if let url = URL(string: "https://github.com/\(self.user)/\(Bundle.main.infoDictionary!["CFBundleExecutable"]!)/releases/tag/v" + latestVersion) {
                                NSWorkspace.shared.open(url)
                            }
                    }
                } catch {
                    // :TODO 加日志
                    print("Error reading plist: \(error), format: \(propertyListForamt)")
                }
            }
        }
    }
}
