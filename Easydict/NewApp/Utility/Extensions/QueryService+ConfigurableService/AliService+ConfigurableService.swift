//
//  AliService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension AliService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(headerTitleKey: "service.configuration.ali.header", service: self, keys: [.aliAccessKeyId, .aliAccessKeySecret]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.ali.access_key_id.title",
                key: .aliAccessKeyId,
                placeholder: "service.configuration.ali.access_key_id.prompt"
            )
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.ali.access_key_secret.title",
                key: .aliAccessKeySecret,
                placeholder: "service.configuration.ali.access_key_secret.prompt"
            )
        }
    }
}
