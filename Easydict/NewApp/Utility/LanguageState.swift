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

var localizedBundle: Bundle {
    let res = UserDefaults.standard.string(forKey: "language")
    let path = Bundle.main.path(forResource: res, ofType: "lproj")
    let bundle: Bundle
    if let path = path {
        bundle = Bundle(path: path) ?? .main
    } else {
        bundle = .main
    }
    return bundle
}
