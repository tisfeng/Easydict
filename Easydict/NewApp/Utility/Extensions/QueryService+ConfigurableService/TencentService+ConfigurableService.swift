//
//  TencentService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension TencentService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(headerTitleKey: "tencent_translate", service: self, keys: [.tencentSecretId, .tencentSecretKey]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.tencent.secret_id.title",
                key: .tencentSecretId,
                placeholder: "service.configuration.input.placeholder"
            )

            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.tencent.secret_key.title",
                key: .tencentSecretKey,
                placeholder: "service.configuration.input.placeholder"
            )
        }
    }
}
