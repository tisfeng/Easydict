//
//  AdvancedTabAnkiSection.swift
//  Easydict
//
//  Created by leexiaobu on 2026/7/9.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import SFSafeSymbols
import SwiftUI

/// Presents the compact entry to Anki Connect settings.
struct AdvancedTabAnkiSection: View {
    // MARK: Internal

    var body: some View {
        Section {
            SheetChevronRow {
                HStack {
                    AdvancedTabItemView(
                        color: enableAnkiConnect ? .green : .red,
                        icon: .externaldriveConnectedToLineBelow,
                        labelText: "setting.advance.header.anki_connect"
                    )
                    Spacer()
                    if enableAnkiConnect {
                        Text("setting.sheet.enabled")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("setting.sheet.disabled")
                            .foregroundStyle(.secondary)
                    }
                }
            } content: {
                AnkiConnectSettingsView()
            }
        }
    }

    // MARK: Private

    @Default(.enableAnkiConnect) private var enableAnkiConnect
}
