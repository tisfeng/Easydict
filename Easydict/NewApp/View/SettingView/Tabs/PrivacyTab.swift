//
//  PrivacyTab.swift
//  Easydict
//
//  Created by Kyle on 2023/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import SwiftUI

@available(macOS 13, *)
struct PrivacyTab: View {
    // MARK: Internal

    var body: some View {
        Form {
            Section {
                Text("privacy_statement_content".localized)
                    .font(.body)
                    .multilineTextAlignment(.leading)
            } header: {
                Text("privacy_statement".localized)
            }
            Section {
                HStack {
                    Text("crash_log".localized)
                    Toggle("allow_collect_crash_log".localized, isOn: $allowCollectCrashLog)
                }
                HStack {
                    Text("analytics".localized)
                    Toggle("allow_collect_analytics".localized, isOn: $allowCollectAnalytics)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Private

    @Default(.allowCrashLog) private var allowCollectCrashLog
    @Default(.allowAnalytics) private var allowCollectAnalytics
}

@available(macOS 13, *)
#Preview {
    PrivacyTab()
}
