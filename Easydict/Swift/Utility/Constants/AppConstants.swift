//
//  AppConstants.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - AppConstants

/// App-wide constants shared by Swift and Objective-C.
///
/// Keep constants used by a single module inside that module instead.
@objcMembers
final class AppConstants: NSObject {
    // MARK: - App

    static let bundleID = "com.izual.Easydict"
    static let debugBundleID = "com.izual.Easydict-debug"

    // MARK: - Repository

    /// Repository full name, eg. tisfeng/Easydict
    static let repoName = "tisfeng/Easydict"
    static let repoURL = URL(string: "https://github.com/\(repoName)")!
    static let releasesURL = repoURL.appending(path: "releases")
    static let issuesURL = repoURL.appending(path: "issues")

    // MARK: - Network

    /// Default timeout for translation requests, in seconds.
    static let networkTimeoutInterval: TimeInterval = 15

    /// Timeout for hand-built LLM chat requests, in seconds.
    ///
    /// Keep this aligned with the MacPaw/OpenAI SDK's default
    /// `OpenAI.Configuration.timeoutInterval` of 60 seconds. The
    /// `URLRequest.timeoutInterval` is an idle timeout, not a total deadline:
    /// it limits how long the request may wait for additional data and resets
    /// whenever bytes arrive.
    ///
    /// The generic `networkTimeoutInterval` is 15 seconds, which is too
    /// short for long non-streaming completions and may end streaming
    /// requests while they wait for the next token. This value applies to
    /// `OpenAIStreamTransport`, the non-streaming fallback, and DeepSeek's
    /// hand-built stream; regular translation APIs remain at 15 seconds.
    static let llmRequestTimeoutInterval: TimeInterval = 60

    /// Mobile browser user agent for web translation APIs.
    static let userAgent =
        "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) "
            + "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"

    // MARK: - Query

    /// Easydict translate shortcut name.
    static let translateShortcutName = "Easydict-Translate-V1.2.0"

    /// Minimum length for classical Chinese text detection, default is 20
    static let minClassicalChineseLength = 20
}
