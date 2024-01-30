//
//  NiuTransTranslate+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension EZNiuTransTranslate: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(headerTitleKey: "service.configuration.niutrans.header", service: self, keys: [.niuTransAPIKey]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.niutrans.api_key.title",
                key: .niuTransAPIKey,
                placeholder: "service.configuration.niutrans.api_key.prompt"
            )
        }
    }
}
