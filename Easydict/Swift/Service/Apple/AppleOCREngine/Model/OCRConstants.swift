//
//  OCRConstants.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCRConstants

/// Constants used for OCR text processing
enum OCRConstants {
    static let lineSeparator = "\n"
    static let paragraphSeparator = "\n\n"

    /// Default is 1.8 characters for indentation, should be less than 2 characters
    static let indentationCharacterCount: Double = 1.8

    /// Maximum ratio of line spacing to line height for normal text layout.
    /// Used to cap excessively large gaps when calculating average line spacing.
    /// Default is 1.2 (120% of line height)
    static let maxLineSpacingHeightRatio: Double = 1.2

    /// Default is 12.0, for Chinese poetry
    static let poetryCharacterCountOfLine = 12.0

    /// Default is 7.0, for English poetry. 《I Pass by in Silence》 is 9.2 characters per line,
    static let poetryWordCountOfLine = 7.0

    /// Increased from 3.5 to 4.0 for better Chinese text detection
    static let chineseDifferenceFontThreshold: Double = 4.0

    /// 5.5 for English text font, may be not precise, so use a larger threshold
    static let englishDifferenceFontThreshold: Double = 5.5

    /// Root directory for logs: ~/Library/Caches/com.izual.Easydic/MMLogs
    static var rootLogDirectoryURL: URL = {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        // Append the bundle identifier to ensure uniqueness, even if sandbox is disabled
        let identifier = Bundle.main.bundleIdentifier!
        let path = cachesDirectory.appending(path: "\(identifier)/MMLogs")
        try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        return path
    }()

    /// Directory for OCR images: ~/Library/Caches/com.izual.Easydic/MMLogs/Image
    static var ocrImageDirectoryURL: URL {
        let directory = rootLogDirectoryURL.appendingPathComponent("Image")
        try? FileManager.default.createDirectory(atPath: directory.path, withIntermediateDirectories: true)
        return URL(fileURLWithPath: directory.path())
    }
}
