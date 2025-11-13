//
//  DoubaoResponse.swift
//  Easydict
//
//  Created by Liaoworking on 2025/9/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - DoubaoStreamEvent

/// Represents a Doubao streaming event for SSE (Server-Sent Events) parsing
/// Only the delta field is used for extracting incremental translation text
struct DoubaoStreamEvent: Codable {
    /// The incremental translation text chunk
    let delta: String?
}
