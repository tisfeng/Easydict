//
//  TencentService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

extension TencentService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.tencentSecretId, .tencentSecretKey]
        ) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.tencent.secret_id.title",
                key: .tencentSecretId
            )

            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.tencent.secret_key.title",
                key: .tencentSecretKey
            )
        }
    }
}
