//
//  AutoPlayAudioExtensions.swift
//  Easydict
//
//  Created by swi on 2025/2/13.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - AutoPlayAudio + Defaults.Serializable

extension AutoPlayAudio: Defaults.Serializable {}

// MARK: - AutoPlayAudio + CaseIterable

extension AutoPlayAudio: CaseIterable {
    public static let allCases: [AutoPlayAudio] = [.disabled, .us, .uk]
}

// MARK: - AutoPlayAudio + CustomLocalizedStringResourceConvertible

extension AutoPlayAudio: CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .disabled:
            "auto_play_audio_disabled"
        case .uk:
            "auto_play_audio_uk"
        case .us:
            "auto_play_audio_us"
        @unknown default:
            "unknown_option"
        }
    }
}
