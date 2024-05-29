//
//  GeminiService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/31.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

extension GeminiService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.geminiAPIKey]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.gemini.api_key.title",
                key: .geminiAPIKey
            )
        }
    }
}
