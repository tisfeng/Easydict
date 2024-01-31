//
//  BingService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/31.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension EZBingService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.bingCookieKey]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.bing.cookie.title",
                key: .bingCookieKey
            )
        }
    }
}
