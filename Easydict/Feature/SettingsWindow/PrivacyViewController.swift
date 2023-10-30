//
//  PrivacyViewController.swift
//  Easydict
//
//  Created by Kyle on 2023/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

import Settings
import SwiftUI

let PrivacyViewController: () -> SettingsPane = {
    let icon = NSImage(
        systemSymbolName: "hand.raised.square",
        accessibilityDescription: nil
    )!.withTintColor(.ez_imageTintBlue())
    let panelView = Settings.Pane(
        identifier: .init("Privacy"),
        title: NSLocalizedString("privacy", comment: "privacy"),
        toolbarIcon: icon
    ) {
        PrivacyPanelView()
    }
    return Settings.PaneHostingController(pane: panelView)
}

struct PrivacyPanelView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("privacy_statement")
                    .settingDescription()
                Text("privacy_statement_content")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)
                HStack {
                    Text("crash_log")
                    Toggle("allow_collect_crash_log", isOn: $allowCollectCrashLog)
                }
                HStack {
                    Text("analytics")
                    Toggle("allow_collect_analytics", isOn: $allowCollectAnalytics)
                }
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 30)
        }
        .frame(idealWidth: 500, idealHeight: 300)
    }

    @AppStorage("EZConfiguration_kAllowCrashLogKey")
    private var allowCollectCrashLog = true

    @AppStorage("EZConfiguration_kAllowAnalyticsKey")
    private var allowCollectAnalytics = true
}

#Preview {
    PrivacyViewController()
}
