//
//  CharacterSet+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/4.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension CharacterSet {
    /// Set of end punctuation marks
    static let endPunctuationMarks = CharacterSet(charactersIn: "。！？.!?;:")

    /// Set of dot-like characters
    static let dotLikeCharacters = CharacterSet(charactersIn: "⋅•‧∙⋄◦∘○●")
}
