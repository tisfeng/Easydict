//
//  WindowConfiguration.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/24.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import SwiftUI

// MARK: - WindowConfigurationView

struct WindowConfigurationView: View {
    // MARK: Lifecycle

    init(windowType: EZWindowType) {
        self.windowType = windowType

        _showInputTextField = .init(
            windowConfigurationKey(
                .inputFieldCellVisible, windowType: windowType, defaultValue: true
            )
        )

        _showSelectLanguageTextField = .init(
            windowConfigurationKey(
                .selectLanguageCellVisible, windowType: windowType, defaultValue: true
            )
        )
    }

    // MARK: Internal

    @Default var showInputTextField: Bool
    @Default var showSelectLanguageTextField: Bool
    let windowType: EZWindowType

    var body: some View {
        Form {
            Section {
                Toggle("setting.service.show_input_text_field", isOn: $showInputTextField)
                    .onChange(of: showInputTextField) { _ in
                        NotificationCenter.default.post(
                            name: .didChangeWindowConfiguration, object: nil
                        )
                    }

                Toggle(
                    "setting.service.show_select_language_text_field",
                    isOn: $showSelectLanguageTextField
                )
                .onChange(of: showSelectLanguageTextField) { _ in
                    NotificationCenter.default.post(
                        name: .didChangeWindowConfiguration, object: nil
                    )
                }
            }
        }
        .formStyle(.grouped)
    }
}
