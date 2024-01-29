//
//  TencentService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension TencentService: ConfigurableService {
    func reset() {
        Defaults[.tencentSecretId] = ""
        Defaults[.tencentSecretKey] = ""
    }

    func validate() {}

    func configurationListItems() -> some View {
        ServiceConfigurationSectionView(headerTitleKey: "service.configuration.tencent.header", service: self) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.tencent.secret_id.title",
                key: .tencentSecretId,
                placeholder: "service.configuration.tencent.secret_id.prompt"
            )

            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.tencent.secret_key.title",
                key: .tencentSecretKey,
                placeholder: "service.configuration.tencent.secret_key.prompt"
            )
        }
    }
}
