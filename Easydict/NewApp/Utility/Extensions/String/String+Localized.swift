//
//  String+Localized.swift
//  Easydict
//
//  Created by Sharker on 2024/2/7.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// ref: https://stackoverflow.com/questions/60841915/how-to-change-localizedstringkey-to-string-in-swiftui
extension LocalizedStringKey {
    // This will mirror the `LocalizedStringKey` so it can access its
    // internal `key` property. Mirroring is rather expensive, but it
    // should be fine performance-wise, unless you are
    // using it too much or doing something out of the norm.
    var stringKey: String? {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String
    }
}

extension String {
    static func localizedString(for key: String,
                                locale: Locale = .current) -> String
    {
        let language = locale.languageCode
        let path = Bundle.main.path(forResource: language, ofType: "lproj")!
        let bundle = Bundle(path: path)!
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")

        return localizedString
    }
}
