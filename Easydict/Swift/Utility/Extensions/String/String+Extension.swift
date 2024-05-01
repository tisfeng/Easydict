//
//  String+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/4/29.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension String {
    func truncated(_ maxLength: Int = 200) -> String {
        String(prefix(maxLength))
    }
}

@objc
extension NSString {
    func truncated() -> NSString {
        truncated(200)
    }

    func truncated(_ maxLength: Int) -> NSString {
        if length > maxLength {
            return substring(to: maxLength) as NSString
        }
        return self
    }
}
