//
//  LanguageState.swift
//  Easydict
//
//  Created by choykarl on 2024/3/3.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// MARK: - LanguageState

final class LanguageState: ObservableObject {
    let languages = [
        "en": "English",
        "zh-CN": "中文",
    ]

    @AppStorage("language") var language = Locale.current.identifier
}

extension String {
    var localized: String {
        NSLocalizedString(self, bundle: localizedBundle, value: "", comment: "")
    }
}

/// https://stackoverflow.com/questions/60841915/how-to-change-localizedstringkey-to-string-in-swiftui
extension LocalizedStringKey {
    // This will mirror the `LocalizedStringKey` so it can access its
    // internal `key` property. Mirroring is rather expensive, but it
    // should be fine performance-wise, unless you are
    // using it too much or doing something out of the norm.
    var stringKey: String? {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String
    }

    var stringKeyLocalized: String {
        (stringKey ?? "").localized
    }
}

var localizedBundle: Bundle {
    EZI18nHelper.shared.localizedBundle
}

// MARK: - EZI18nHelper

@objcMembers
class EZI18nHelper: NSObject {
    static let shared = EZI18nHelper()

    var localizedBundle: Bundle {
        let res = localizeCode
        let path = Bundle.main.path(forResource: res, ofType: "lproj")
        let bundle: Bundle
        if let path = path {
            bundle = Bundle(path: path) ?? .main
        } else {
            bundle = .main
        }
        return bundle
    }

    var localizeCode: String {
        UserDefaults.standard.string(forKey: "language") ?? "zh-CN"
    }

    class func localized(key: String) -> String {
        key.localized
    }
}
