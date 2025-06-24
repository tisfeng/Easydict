//
//  AppleOCRConstants.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCR Text Processing Constants

/// Constants used for OCR text processing and merging
enum AppleOCRConstants {
    /// Line break character
    static let lineBreakText = "\n"

    /// Paragraph break characters
    static let paragraphBreakText = "\n\n"

    /// Indentation text (currently empty)
    static let indentationText = ""

    /// Ratio threshold for paragraph line height detection
    static let paragraphLineHeightRatio: CGFloat = 1.5

    /// Maximum character count per line for short poetry detection
    static let shortPoetryCharacterCountOfLine = 12
}
