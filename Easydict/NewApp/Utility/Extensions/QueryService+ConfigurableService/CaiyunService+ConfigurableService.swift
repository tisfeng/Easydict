//
//  CaiyunService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension CaiyunService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(headerTitleKey: "service.configuration.caiyun.header", service: self, keys: [.caiyunToken]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.caiyun.token.title",
                key: .caiyunToken,
                placeholder: "service.configuration.caiyun.token.prompt"
            )
        }
    }
}
