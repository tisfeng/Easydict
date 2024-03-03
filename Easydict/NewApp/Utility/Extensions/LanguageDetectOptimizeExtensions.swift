//
//  LanguageDetectOptimizeExtensions.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - LanguageDetectOptimize + Defaults.Serializable

extension LanguageDetectOptimize: Defaults.Serializable {}

// MARK: - LanguageDetectOptimize + CaseIterable

extension LanguageDetectOptimize: CaseIterable {
    public static let allCases: [LanguageDetectOptimize] = [.none, .baidu, .google]
}

// MARK: - LanguageDetectOptimize + CustomLocalizedStringResourceConvertible

@available(macOS 13, *)
extension LanguageDetectOptimize {
    public var localizedStringResource: String {
        switch self {
        case .none:
            "language_detect_optimize_none".localized
        case .google:
            "language_detect_optimize_google".localized
        case .baidu:
            "language_detect_optimize_baidu".localized
        @unknown default:
            "unknown_option".localized
        }
    }
}
