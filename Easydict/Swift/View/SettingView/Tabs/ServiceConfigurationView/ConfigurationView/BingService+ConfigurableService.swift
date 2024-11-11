//
//  BingService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/31.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

extension EZBingService {
    open override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.bingCookieKey]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.bing.cookie.title",
                key: .bingCookieKey
            )
        }
    }
}
