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
        map { $0.toTraditionalChinese() }
    }
}

@objc
extension NSArray {
    /// Trim to max count
    func trim(toMaxCount maxCount: Int) -> NSArray {
        guard maxCount > 0, maxCount < count else { return self }
        let array = subarray(with: NSRange(location: 0, length: maxCount)) as NSArray
        return array
    }

    /// Convert translated results to Traditional Chinese manually.  开门 --> 開門
    func toTraditionalChineseTexts() -> NSArray {
        mapStringElements { $0.toTraditionalChineseText() }
    }

    /// Convert translated results to Simplified Chinese manually.  開門 --> 开门
    func toSimplifiedChineseTexts() -> NSArray {
        mapStringElements { $0.toSimplifiedChineseText() }
    }

    func removeExtraLineBreaks() -> NSArray {
        mapStringElements { $0.ns_removeExtraLineBreaks() as NSString }
    }
}

extension NSArray {
    fileprivate func mapStringElements(_ transform: (NSString) -> NSString) -> NSArray {
        let transformed = compactMap { element -> NSString? in
            switch element {
            case let string as NSString:
                return transform(string)
            case let string as String:
                return transform(string as NSString)
            default:
                return nil
            }
        }
        return transformed as NSArray
    }
}

extension Array {
    /// Convert the array to a pretty-printed JSON string.
    var prettyPrinted: NSString {
        let jsonData = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
        if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString as NSString
        }
        return "[]"
    }
}
