//
//  BingTranslateResponse.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - BingTranslateModel

/// Bing translate response model
struct BingTranslateModel: Codable {
    // MARK: - Detected Language

    let detectedLanguage: BingDetectedLanguage?
    let translations: [BingTranslation]?
}

// MARK: - BingDetectedLanguage

/// Detected source language, example: en, zh-Hans...
struct BingDetectedLanguage: Codable {
    let language: String?
    let score: Double?
}

// MARK: - BingTranslation

/// Translation result
struct BingTranslation: Codable {
    /// Translated text
    let text: String?
    let transliteration: BingTransliteration?
    /// Target language, example: en, zh-Hans...
    let to: String?
    let sentLen: BingSentLen?
}

// MARK: - BingTransliteration

struct BingTransliteration: Codable {
    let text: String?
    let script: String?
}

// MARK: - BingSentLen

struct BingSentLen: Codable {
    let srcSentLen: [Int]?
    let transSentLen: [Int]?
}
