//
//  BaiduService+ConfigurableService.swift
//  Easydict
//
//  Created by karl on 2024/7/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation
import SwiftUI

extension EZBaiduTranslate {
    open override func configurationListItems() -> Any {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.baiduAppId, .baiduSecretKey]
        ) {
            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.baidu.api_picker.title",
                key: .baiduServiceApiTypeKey,
                values: ServiceAPIType.allCases
            )

            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.baidu.app_id.title",
                key: .baiduAppId
            )

            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.baidu.secret_key.title",
                key: .baiduSecretKey
            )
        }
    }
}

// MARK: - ServiceAPIType

enum ServiceAPIType: String, CaseIterable, Defaults.Serializable, EnumLocalizedStringConvertible {
    case web = "Web API"
    case secretKey = "Secret Key API"

    // MARK: Internal

    var title: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
}
