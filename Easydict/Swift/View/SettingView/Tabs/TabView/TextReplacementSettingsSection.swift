//
//  TextReplacementSettingsSection.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - TextReplacementSettingsSection

/// Configures the provider and optional additional instruction for both replacement actions.
///
/// Provider options reflect configured services across every window while the four action
/// preferences remain global and independent of window enablement.
struct TextReplacementSettingsSection: View {
    // MARK: Internal

    var body: some View {
        Section {
            TextReplacementActionSettingsGroup(
                titleKey: "menu_translate_and_replace",
                selection: $translateServiceIdentifier,
                options: translateOptions,
                promptKey: .translateAndReplaceAdditionalPrompt
            )

            Divider()

            TextReplacementActionSettingsGroup(
                titleKey: "menu_polish_and_replace",
                selection: $polishServiceIdentifier,
                options: polishOptions,
                promptKey: .polishAndReplaceAdditionalPrompt
            )
        } header: {
            Text("setting.advance.text_replacement.header")
        } footer: {
            Text("setting.advance.text_replacement.footer")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear(perform: reloadOptions)
        .onReceive(serviceHasUpdatedNotification) { _ in
            reloadOptions()
        }
    }

    // MARK: Private

    @State private var translateOptions: [TextReplacementServiceOption] = []
    @State private var polishOptions: [TextReplacementServiceOption] = []

    @Default(.translateAndReplaceServiceIdentifier) private var translateServiceIdentifier

    @Default(.polishAndReplaceServiceIdentifier) private var polishServiceIdentifier

    private let factory = QueryServiceFactory.shared
    private let serviceHasUpdatedNotification = NotificationCenter.default
        .publisher(for: .serviceHasUpdated)

    private func reloadOptions() {
        translateOptions = factory.textReplacementServiceOptions(for: .translate)
        polishOptions = factory.textReplacementServiceOptions(for: .polish)

        if !translateOptions.contains(where: { $0.identifier == translateServiceIdentifier }) {
            translateServiceIdentifier = TextReplacementAction.translate.defaultServiceIdentifier
        }
        if !polishOptions.contains(where: { $0.identifier == polishServiceIdentifier }) {
            polishServiceIdentifier = TextReplacementAction.polish.defaultServiceIdentifier
        }
    }
}

// MARK: - TextReplacementActionSettingsGroup

/// Renders one action's service picker and its independently persisted additional instruction.
private struct TextReplacementActionSettingsGroup: View {
    let titleKey: LocalizedStringKey
    @Binding var selection: String

    let options: [TextReplacementServiceOption]
    let promptKey: Defaults.Key<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titleKey)
                .font(.headline)

            Picker(
                "setting.advance.text_replacement.online_service",
                selection: $selection
            ) {
                ForEach(options) { option in
                    Text(
                        verbatim: option.displayName(
                            missingModelText: String(
                                localized: "setting.advance.text_replacement.model_unconfigured"
                            )
                        )
                    )
                    .tag(option.identifier)
                    .help(option.identifier)
                }
            }

            TextEditorCell(
                titleKey: "setting.advance.text_replacement.additional_prompt",
                storedValueKey: promptKey,
                placeholder: "setting.advance.text_replacement.additional_prompt_placeholder",
                minHeight: 64,
                maxHeight: 96
            )
        }
        .padding(.vertical, 4)
    }
}
