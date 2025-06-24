//
//  String+OCR.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/24.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension String {
    /// Check if the string starts with a capital letter
    var isFirstLetterUpperCase: Bool {
        guard let firstCharacter = first else {
            return false
        }
        return firstCharacter.isUppercase && firstCharacter.isLetter
    }
}
