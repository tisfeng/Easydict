//
//  InPlaceRenderSnapshot.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Foundation

// MARK: - InPlaceRenderSnapshot

/// An immutable image-and-block snapshot whose members all belong to the same
/// processing generation.
struct InPlaceRenderSnapshot: @unchecked Sendable {
    let generation: UInt64
    let image: CGImage
    let blocks: [InPlaceTranslatedBlock]
    let capturedAt: TimeInterval
    let detectedLanguage: Language

    var translatedBlockCount: Int {
        blocks.count { $0.status == .translated }
    }
}
