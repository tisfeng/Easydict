//
//  DoubaoTranslate+ConfigurableView.swift
//  Easydict
//
//  Created by Liaoworking on 2025/9/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - DoubaoService + ConfigurableService

extension DoubaoService {
    public override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.doubaoAPIKey, .doubaoModel]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.doubao.api_key.title",
                key: .doubaoAPIKey
            )

            InputCell(
                textFieldTitleKey: "service.configuration.doubao.model.title",
                key: .doubaoModel,
                placeholder: "doubao-seed-translation-250915",
                limitLength: 100
            )
        }
    }
}
