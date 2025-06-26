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

    /// Ratio threshold for paragraph line height detection, default is 1.5
    static let paragraphLineHeightRatio: CGFloat = 1.5

    /// Maximum character count per line for short poetry detection, default is 12
    static let shortPoetryCharacterCountOfLine = 12

    /// Indentation character count, default is 1.2
    static let indentationCharacterCount = 1.2

    /// Chinese difference font threshold, default is 3
    /// Chinese fonts seem to be more precise.
    static let chineseDifferenceFontThreshold = 3.0

    /// English difference font threshold, default is 5
    /// Note: English uppercase-lowercase font size is not precise, so threshold should a bit large.
    static let englishDifferenceFontThreshold = 5.0
}
