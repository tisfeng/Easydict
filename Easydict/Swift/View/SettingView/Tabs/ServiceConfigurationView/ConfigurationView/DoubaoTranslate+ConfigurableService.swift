//
//  DoubaoTranslate+ConfigurableVIew.swift
//  Easydict
//
//  Created by liao on 2025/9/29.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - CaiyunService + ConfigurableService

extension DoubaoService {
    public override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.doubaoAPIKey]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.doubao.api_key.title",
                key: .doubaoAPIKey
            )
        }
    }
}
