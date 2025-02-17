//
//  AutoPlayAudioExtensions.swift
//  Easydict
//
//  Created by swi on 2025/2/13.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - Pronunciation + Defaults.Serializable

extension Pronunciation: Defaults.Serializable {}

// MARK: - Pronunciation + CaseIterable

extension Pronunciation: CaseIterable {
    public static let allCases: [Pronunciation] = [.us, .uk]
}

// MARK: - Pronunciation + CustomLocalizedStringResourceConvertible

extension Pronunciation: CustomLocalizedStringResourceConvertible {
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
