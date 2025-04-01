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
        print("\n=========== Classical Chinese Detection ===========")
        print("Text: \(self)")

        // Create ChineseText instance to analyze the text
        let chineseText = ChineseText(self)
        chineseText.detect()

        // Log analysis results
        print("\nAnalysis results:")
        if let title = chineseText.title {
            print("- Title: \(title)")
        }
        if let author = chineseText.author {
            print("- Author: \(author)")
        }
        if let dynasty = chineseText.dynasty {
            print("- Dynasty: \(dynasty)")
        }
        print("- Content: \(chineseText.content)")

        print("- Type: \(chineseText.type)")

        // Return true for any classical Chinese type
        return chineseText.type != .modern
    }
}
