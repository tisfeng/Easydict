//
//  BaiduService+ConfigurableService.swift
//  Easydict
//
//  Created by karl on 2024/7/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

extension BaiduService {
    public override func configurationListItems() -> Any {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.baiduAppId, .baiduSecretKey]
        ) {
            StaticPickerCell(
                titleKey: "service.configuration.api_picker.title",
                key: .baiduServiceApiTypeKey,
                values: ServiceAPIType.allCases
            )

            SecureInputCell(
                textFieldTitleKey: "service.configuration.baidu.app_id.title",
                key: .baiduAppId
            )

            SecureInputCell(
                textFieldTitleKey: "service.configuration.baidu.secret_key.title",
                key: .baiduSecretKey
            )
        }
    }
}
