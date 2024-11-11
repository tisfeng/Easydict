//
//  DeepLTranslate+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/30.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

extension EZDeepLTranslate {
    open override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.deepLAuth]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.deepl.auth_key.title",
                key: .deepLAuth
            )

            InputCell(
                textFieldTitleKey: "service.configuration.deepl.endpoint.title",
                key: .deepLTranslateEndPointKey,
                placeholder: "service.configuration.deepl.endpoint.placeholder"
            )

            StaticPickerCell(
                titleKey: "service.configuration.deepl.translation.title",
                key: .deepLTranslation,
                values: DeepLAPIUsagePriority.allCases
            )
        }
    }
}

// MARK: - DeepLAPIUsagePriority

enum DeepLAPIUsagePriority: String, CaseIterable {
    case webFirst = "0"
    case authKeyFirst = "1"
    case authKeyOnly = "2"
}

// MARK: Defaults.Serializable

extension DeepLAPIUsagePriority: Defaults.Serializable {}

// MARK: EnumLocalizedStringConvertible

extension DeepLAPIUsagePriority: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .webFirst:
            "service.configuration.deepl.web_first.title"
        case .authKeyFirst:
            "service.configuration.deepl.authkey_first.title"
        case .authKeyOnly:
            "service.configuration.deepl.authkey_only.title"
        }
    }
}
