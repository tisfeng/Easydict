//
//  InPlaceTranslationSettingsSection.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import SFSafeSymbols
import SwiftUI

// MARK: - InPlaceTranslationSettingsSection

/// Configures durable defaults for new in-place screenshot translation sessions.
struct InPlaceTranslationSettingsSection: View {
    // MARK: Internal

    var body: some View {
        Section {
            Picker(
                selection: $serviceIdentifier,
                label: AdvancedTabItemView(
                    color: .blue,
                    icon: .cameraViewfinder,
                    labelText: "in_place_screenshot_translation.settings.service"
                )
            ) {
                if serviceOptions.isEmpty {
                    Text("in_place_screenshot_translation.status.service_unavailable")
                        .tag("")
                } else {
                    ForEach(serviceOptions) { option in
                        Text(verbatim: option.displayName)
                            .tag(option.identifier)
                            .help(option.identifier)
                    }
                }
            }
            .disabled(serviceOptions.isEmpty)

            Toggle(isOn: $liveUpdatesEnabled) {
                AdvancedTabItemView(
                    color: .green,
                    icon: .arrowClockwise,
                    labelText: "in_place_screenshot_translation.settings.live_updates"
                )
            }

            Toggle(isOn: $isPinned) {
                AdvancedTabItemView(
                    color: .orange,
                    icon: .pinFill,
                    labelText: "in_place_screenshot_translation.settings.pinned"
                )
            }
        } header: {
            Text("in_place_screenshot_translation.settings.header")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("in_place_screenshot_translation.settings.service_source_hint")
                Text("in_place_screenshot_translation.privacy.notice")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear(perform: reloadServices)
        .onReceive(serviceHasUpdatedNotification) { _ in
            reloadServices()
        }
    }

    // MARK: Private

    @State private var serviceOptions: [InPlaceTranslationServiceOption] = []

    @Default(.inPlaceTranslationServiceIdentifier) private var serviceIdentifier
    @Default(.inPlaceTranslationLiveUpdatesEnabled) private var liveUpdatesEnabled
    @Default(.inPlaceTranslationPinned) private var isPinned

    private let resolver = InPlaceTranslationServiceResolver()
    private let serviceHasUpdatedNotification = NotificationCenter.default
        .publisher(for: .serviceHasUpdated)

    private func reloadServices() {
        let options = resolver.options()
        serviceOptions = options

        let resolution = resolver.resolveSelection(
            serviceIdentifier,
            availableOptions: options
        )
        if resolution.shouldResetStoredSelection {
            serviceIdentifier = resolution.identifier ?? ""
        }
    }
}
