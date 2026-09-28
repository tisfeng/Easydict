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
    /// Keep this aligned with the MacPaw/OpenAI SDK's default
    /// `OpenAI.Configuration.timeoutInterval` of 60 seconds. The
    /// `URLRequest.timeoutInterval` is an idle timeout, not a total deadline:
    /// it limits how long the request may wait for additional data and resets
    /// whenever bytes arrive.
    ///
    /// The generic `EZNetWorkTimeoutInterval` is 15 seconds, which is too
    /// short for long non-streaming completions and may end streaming
    /// requests while they wait for the next token. This value applies to
    /// `OpenAIStreamTransport`, the non-streaming fallback, and DeepSeek's
    /// hand-built stream; regular translation APIs remain at 15 seconds.
    static let llmRequestTimeoutInterval: TimeInterval = 60
}
