//
//  BaiduService+ConfigurableService.swift
//  Easydict
//
//  Created by karl on 2024/7/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

extension EZBaiduTranslate {
    open override func configurationListItems() -> Any {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.baiduAppId, .baiduSecretKey]
        ) {
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
