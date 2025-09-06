//
//  AliService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

extension AliService {
    override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.aliAccessKeyId, .aliAccessKeySecret]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.ali.access_key_id.title",
                key: .aliAccessKeyId
            )
            SecureInputCell(
                textFieldTitleKey: "service.configuration.ali.access_key_secret.title",
                key: .aliAccessKeySecret
            )
        }
    }
}
