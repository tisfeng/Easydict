//
//  Constants.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - SharedConstants

enum SharedConstants {
    // Easydict translate shortcut name.
    static let easydictTranslateShortcutName = "Easydict-Translate-V1.2.0"

    /// Minimum length for classical Chinese text detection, default is 20
    static let minClassicalChineseLength = 20

    /// Timeout for hand-built LLM chat requests, in seconds.
    ///
    /// `URLRequest.timeoutInterval` is the maximum gap between received
    /// bytes, not a total deadline. A non-streaming completion only sends
    /// bytes once the whole answer is generated, which already takes longer
    /// than the generic `EZNetWorkTimeoutInterval` (15s) for a few thousand
    /// characters of input (measured: a 2250-character translation on
    /// deepseek-v4-pro timed out at 15s and completed in 11s at 90s).
    /// Streaming requests share the value so a slow first token or a model
    /// that does not stream its reasoning cannot end the stream early with
    /// a partial answer that would then be rendered as complete.
    static let llmRequestTimeoutInterval: TimeInterval = 90
}
