//
//  String+ClassicalChinese.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - Classical Chinese Detection

@objc
extension NSString {
    /// Detect if the text is classical Chinese
    public func isClassicalChinese() -> Bool {
        (self as String).isClassicalChinese()
    }
}

extension String {
    // MARK: - Public Methods

    /// Analyze if the string is classical Chinese based on linguistic features.
    /// This includes detecting classical poetry (格律诗), ci (词), and classical prose.
    /// - Returns: True if text is classical Chinese, false otherwise.
    public func isClassicalChinese() -> Bool {
        let chineseText = ChineseDetection(text: self)
        return chineseText.detect().genre != .modern
    }
}
