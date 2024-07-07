//
//  URL+IsValid.swift
//  Easydict
//
//  Created by tisfeng on 2024/3/24.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension URL {
    var isValid: Bool {
        scheme != nil && host != nil
    }

    /// Get true base URL, such as `http://localhost:11434/v1/chat/completions` return `http://localhost:11434`
    ///
    /// From `https://stackoverflow.com/a/15897956/8378840`
    var rootURL: URL? {
        URL(string: "/", relativeTo: self)?.absoluteURL
    }
}
