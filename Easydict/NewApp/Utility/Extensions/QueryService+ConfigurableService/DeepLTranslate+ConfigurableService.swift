//
//  DeepLTranslate+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/30.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension EZDeepLTranslate: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(headerTitleKey: "deepL_translate", service: self, keys: [.deepLAuth]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.deepl.auth_key.title",
                key: .deepLAuth,
                placeholder: "service.configuration.input.placeholder"
            )

            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.deepl.endpoint.title",
                key: .deepLTranslateEndPointKey,
                placeholder: "service.configuration.deepl.endpoint.placeholder"
            )
        }
    }
}
