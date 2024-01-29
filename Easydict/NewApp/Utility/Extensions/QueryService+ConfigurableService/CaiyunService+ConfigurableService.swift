//
//  CaiyunService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension CaiyunService: ConfigurableService {
    func resetSecret() {
        //        Defaults[.caiyunToken] = ""
        print("CaiyunService reset")
    }

    func validate() {
        print("CaiyunService validate")
    }

    func configurationListItems() -> some View {
        ServiceConfigurationSectionView(headerTitleKey: "service.configuration.caiyun.header", service: self) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.caiyun.token.title",
                key: .caiyunToken,
                placeholder: "service.configuration.caiyun.token.prompt"
            )
        }
    }
}
