//
//  NiuTransTranslate+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension EZNiuTransTranslate: ConfigurableService {
    func reset() {
        Defaults[.niuTransAPIKey] = ""
    }

    func validate() {}

    func configurationListItems() -> some View {
        ServiceConfigurationSectionView(headerTitleKey: "service.configuration.niutrans.header", service: self) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.niutrans.api_key.title",
                key: .caiyunToken,
                placeholder: "service.configuration.niutrans.api_key.prompt"
            )
        }
    }
}
