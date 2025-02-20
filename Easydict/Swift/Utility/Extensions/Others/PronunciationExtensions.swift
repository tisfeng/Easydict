//
//  AutoPlayAudioExtensions.swift
//  Easydict
//
//  Created by swi on 2025/2/13.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - EnglishPronunciation + Defaults.Serializable

extension EnglishPronunciation: Defaults.Serializable {}

// MARK: - EnglishPronunciation + CaseIterable

extension EnglishPronunciation: CaseIterable {
    public static let allCases: [EnglishPronunciation] = [.us, .uk]
}

// MARK: - EnglishPronunciation + CustomLocalizedStringResourceConvertible

extension EnglishPronunciation: CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .uk:
            "pronunciation_uk"
        case .us:
            "pronunciation_us"
        @unknown default:
            "unknown_option"
        }
    }
}
