//
//  SelectedTextSnapshot.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - SelectedTextSnapshot

/// Captures selected text with metadata for downstream handlers.
struct SelectedTextSnapshot {
    let text: String?
    let selectTextType: EZSelectTextType
    let isEditable: Bool
}
