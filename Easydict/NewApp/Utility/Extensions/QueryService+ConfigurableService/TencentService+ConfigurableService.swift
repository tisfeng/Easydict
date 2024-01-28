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
        ServiceStringConfigurationSection(
            textFieldTitleKey: "service.configuration.tencent.secret_id.header",
            headerTitleKey: "service.configuration.tencent.secret_id.title",
            key: .tencentSecretId,
            prompt: "service.configuration.tencent.secret_id.prompt",
            footer: {
                Text("service.configuration.tencent.secret_id.footer")
            }
        )

        ServiceStringConfigurationSection(
            textFieldTitleKey: "service.configuration.tencent.secret_key.header",
            headerTitleKey: "service.configuration.tencent.secret_key.title",
            key: .tencentSecretKey,
            prompt: "service.configuration.tencent.secret_key.prompt",
            footer: {
                Text("service.configuration.tencent.secret_key.footer")
            }
        )
    }
}
