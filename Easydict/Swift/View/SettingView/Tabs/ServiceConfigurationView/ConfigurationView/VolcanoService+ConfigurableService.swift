//
//  VolcanoService+ConfigurableService.swift
//  Easydict
//
//  Created by Jerry on 2024-08-12.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

extension VolcanoService {
    public override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.volcanoAccessKeyID, .volcanoSecretAccessKey]
        ) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.volcano.access_id.title",
                key: .volcanoAccessKeyID
            )
            SecureInputCell(
                textFieldTitleKey: "service.configuration.volcano.secret_key.title",
                key: .volcanoSecretAccessKey
            )
        }
    }
}
