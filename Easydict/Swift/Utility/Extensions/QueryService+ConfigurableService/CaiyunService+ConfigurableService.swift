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
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.caiyunToken]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.caiyun.token.title",
                key: .caiyunToken
            )
        }
    }
}
