//
//  Array+Convenience.swift
//  Easydict
//
//  Created by tisfeng on 2023/11/26.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

extension [String] {
    func toTraditionalChineseTexts() -> [String] {
        map { text in
            let nsStringText = text as NSString
            return nsStringText.toTraditionalChineseText()
        }
    }
}

@objc extension NSArray {
    /// Trim to max count
    func trim(toMaxCount maxCount: Int) -> NSArray {
        guard maxCount > 0, maxCount < count else { return self }
        let array = subarray(with: NSRange(location: 0, length: maxCount)) as NSArray
        return array
    }
}
