//
//  InPlaceTranslatedBlock.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - InPlaceBlockTranslationStatus

/// Describes whether an OCR block has a usable translation for the active generation.
enum InPlaceBlockTranslationStatus: Equatable, Sendable {
    case pending
    case translated
    case failed(InPlaceTranslationErrorCategory)
}

// MARK: - InPlaceTranslatedBlock

/// Combines one positioned OCR block with its generation-scoped translation state.
struct InPlaceTranslatedBlock: Identifiable, Equatable, Sendable {
    let block: InPlaceOCRBlock
    let translatedText: String?
    let status: InPlaceBlockTranslationStatus
    let providerIdentifier: String

    var id: UUID {
        block.id
    }
}
