//
//  BingLookupResponse.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - BingLookupModel

/// Bing lookup response model
struct BingLookupModel: Codable {
    let normalizedSource: String?
    let displaySource: String?
    let translations: [BingLookupTranslation]?
}

// MARK: - BingLookupTranslation

struct BingLookupTranslation: Codable {
    let normalizedTarget: String?
    let displayTarget: String?
    let posTag: String?
    let confidence: Double?
    let prefixWord: String?
    let backTranslations: [BingLookupBackTranslation]?
}

// MARK: - BingLookupBackTranslation

struct BingLookupBackTranslation: Codable {
    let normalizedText: String?
    let displayText: String?
    let numExamples: Int?
    let frequencyCount: Int?
}
