//
//  String+ToChinese.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/5.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension String {
    /// Convert Simplified Chinese to Traditional Chinese. 开门 --> 開門
    func toTraditionalChinese() -> String {
        applyingTransform(.init("Hans-Hant"), reverse: false) ?? self
    }

    /// Convert Traditional Chinese to Simplified Chinese. 開門 --> 开门
    func toSimplifiedChinese() -> String {
        applyingTransform(.init("Hant-Hans"), reverse: false) ?? self
    }
}
