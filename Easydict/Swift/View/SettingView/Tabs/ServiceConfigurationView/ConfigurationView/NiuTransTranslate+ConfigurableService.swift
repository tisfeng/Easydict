//
//  NiuTransTranslate+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - EZNiuTransTranslate + ConfigurableService

extension EZNiuTransTranslate {
    open override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.niuTransAPIKey]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.niutrans.api_key.title",
                key: .niuTransAPIKey
            )
        }
    }
}
