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
    @Default(.liquidGlassMini) private var liquidGlassMini
    @Default(.liquidGlassMiniService) private var liquidGlassMiniService
    @State private var glassServices: [QueryService] = []
    let windowType: EZWindowType

    var body: some View {
        Form {
            if windowType == .mini {
                Section {
                    if #available(macOS 26.0, *) {
                        NotifyingToggle(
                            title: "glass.mini.setting.enabled",
                            isOn: $liquidGlassMini,
                            windowType: windowType
                        )
                        if liquidGlassMini {
                            Picker("glass.mini.setting.service", selection: $liquidGlassMiniService) {
                                ForEach(glassServices.indices, id: \.self) { index in
                                    let service = glassServices[index]
                                    Text(service.name()).tag(service.serviceTypeWithUniqueIdentifier())
                                }
                                if !glassServices.contains(where: {
                                    $0.serviceTypeWithUniqueIdentifier() == liquidGlassMiniService
                                }) {
                                    Text("glass.mini.setting.choose_service").tag(liquidGlassMiniService)
                                }
                            }
                            .onChange(of: liquidGlassMiniService) { _ in
                                let info = UpdateNotificationInfo(windowType: .mini)
                                NotificationCenter.default.post(name: .didChangeWindowConfiguration, object: info)
                            }
                            Text("glass.mini.setting.description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("glass.mini.setting.requirement")
                            .foregroundStyle(.secondary)
                    }
                }
            }
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
            .disabled(windowType == .mini && GlassMiniConfiguration.enabled)
        }
        .formStyle(.grouped)
        .onAppear { glassServices = GlassMiniConfiguration.availableServices() }
        .onReceive(NotificationCenter.default.publisher(for: .serviceHasUpdated)) { _ in
            glassServices = GlassMiniConfiguration.availableServices()
        }
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
