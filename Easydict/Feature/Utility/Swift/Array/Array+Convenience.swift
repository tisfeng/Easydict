//
//  Array+ChineseTextConversion.swift
//  Easydict
//
//  Created by tisfeng on 2023/11/26.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

extension Array where Element == String {
    func toTraditionalChineseTexts() -> [String] {
        return self.map { text in
            let nsStringText = text as NSString
            return nsStringText.toTraditionalChineseText()
        }
    }
}

@objc extension NSArray {
    /// Trim to max count
    func trim(toMaxCount maxCount: Int) -> NSArray {
        guard maxCount > 0 && maxCount < self.count else { return self }
        let array = self.subarray(with: NSRange(location: 0, length: maxCount)) as NSArray
        return array
    }
}
