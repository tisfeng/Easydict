//
//  NewConfiguration+UserData.swift
//  Easydict
//
//  Created by ljk on 2024/1/17.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension Configuration {
    var userDefaultsData: [String: Any] {
        let userDefaults = UserDefaults.standard

        var userConfigDict = [String: Any]()
        if let bundleIdentifier = Bundle.main.bundleIdentifier, let appUserDefaultsData = userDefaults.persistentDomain(forName: bundleIdentifier) {
            for (key, value) in appUserDefaultsData {
                if !key.hasPrefix("MASPreferences"), !(value is Data) {
                    userConfigDict[key] = value
                }
            }
        }

        return userConfigDict
    }

    func saveUserDefaultsDataToDownloadFolder() {
        writeDictToDownloadFolder(userDefaultsData)
    }

    func resetUserDefaultsData() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
    }

    func writeDictToDownloadFolder(_ dict: [String: Any]) {
        let downloadPath = downloadPath
        let name = ProcessInfo.processInfo.processName
        let date = currentDate
        let fileName = "\(name)_\(date).plist"
        let plistPath = (downloadPath as NSString?)?.appendingPathComponent(fileName)
        guard let path = plistPath else { return }

        let plistData = try? PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
        try? plistData?.write(to: URL(fileURLWithPath: path))
    }

    var downloadPath: String? {
        NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).first
    }

    var currentDate: String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        let formattedDate = formatter.string(from: currentDate)
        print("Formatted Date: ", formattedDate)

        return formattedDate
    }
}
