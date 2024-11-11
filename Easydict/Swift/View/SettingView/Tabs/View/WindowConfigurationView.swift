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
                NotifyingToggle(
                    title: "setting.service.show_input_text_field",
                    isOn: $showInputTextField,
                    windowType: windowType
                )

                NotifyingToggle(
                    title: "setting.service.show_select_language_bar",
                    isOn: $showSelectLanguageTextField,
                    windowType: windowType
                )
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - NotifyingToggle

struct NotifyingToggle: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    let windowType: EZWindowType

    var body: some View {
        Toggle(title, isOn: $isOn)
            .onChange(of: isOn) { _ in
                let info = UpdateNotificationInfo(windowType: windowType)
                NotificationCenter.default.post(name: .didChangeWindowConfiguration, object: info)
            }
    }
}
