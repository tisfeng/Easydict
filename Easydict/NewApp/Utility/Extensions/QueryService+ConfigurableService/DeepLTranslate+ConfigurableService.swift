//
//  DeepLTranslate+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/30.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

enum DeepLAPIUsagePriority: String, CaseIterable, Hashable {
    case webFirst = "0"
    case authKeyFirst = "1"
    case authKeyOnly = "2"
}

extension DeepLAPIUsagePriority: EnumLocalizedStringConvertible {
    var title: String {
        switch self {
        case .webFirst:
            return NSLocalizedString("service.configuration.deepl.web_first.title", bundle: .main, comment: "")
        case .authKeyFirst:
            return NSLocalizedString("service.configuration.deepl.authkey_first.title", bundle: .main, comment: "")
        case .authKeyOnly:
            return NSLocalizedString("service.configuration.deepl.authkey_only.title", bundle: .main, comment: "")
        }
    }
}

@available(macOS 13.0, *)
extension EZDeepLTranslate: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.deepLAuth]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.deepl.auth_key.title",
                key: .deepLAuth
            )

            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.deepl.endpoint.title",
                key: .deepLTranslateEndPointKey,
                placeholder: "service.configuration.deepl.endpoint.placeholder"
            )

            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.deepl.translation.title",
                key: .deepLTranslation,
                values: DeepLAPIUsagePriority.allCases
            )
        }
    }
}
