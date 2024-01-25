//
//  LanguageDetectOptimizeExtensions.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

extension LanguageDetectOptimize: Defaults.Serializable {}

extension LanguageDetectOptimize: CaseIterable {
    public static let allCases: [LanguageDetectOptimize] = [.none, .baidu, .google]
}

@available(macOS 13, *)
extension LanguageDetectOptimize: CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .none:
            "language_detect_optimize_none"
        case .google:
            "language_detect_optimize_google"
        case .baidu:
            "language_detect_optimize_baidu"
        @unknown default:
            "unknown_option"
        }
    }
}
