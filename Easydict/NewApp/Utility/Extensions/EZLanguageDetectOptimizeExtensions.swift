//
//  EZLanguageDetectOptimizeExtensions.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

extension EZLanguageDetectOptimize: Defaults.Serializable {}

extension EZLanguageDetectOptimize: CaseIterable {
    public static let allCases: [EZLanguageDetectOptimize] = [.none, .baidu, .google]
}

@available(macOS 13, *)
extension EZLanguageDetectOptimize: CustomLocalizedStringResourceConvertible {
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
