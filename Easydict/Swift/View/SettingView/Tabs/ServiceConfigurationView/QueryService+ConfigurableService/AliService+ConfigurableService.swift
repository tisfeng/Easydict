//
//  AliService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

extension AliService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.aliAccessKeyId, .aliAccessKeySecret]
        ) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.ali.access_key_id.title",
                key: .aliAccessKeyId
            )
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.ali.access_key_secret.title",
                key: .aliAccessKeySecret
            )
        }
    }
}
