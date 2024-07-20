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
                values: BaiduServiceApiType.allCases
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

// MARK: - BaiduServiceApiType

enum BaiduServiceApiType: String, CaseIterable, Defaults.Serializable {
    case web = "0"
    case secretKey = "1"
}

// MARK: EnumLocalizedStringConvertible

extension BaiduServiceApiType: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .web:
            "service.configuration.baidu.web_api_type.title"
        case .secretKey:
            "service.configuration.baidu.secret_key_api_type.title"
        }
    }
}
