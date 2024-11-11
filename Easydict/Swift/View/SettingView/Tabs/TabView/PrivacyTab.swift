//
//  PrivacyTab.swift
//  Easydict
//
//  Created by Kyle on 2023/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import SwiftUI

struct PrivacyTab: View {
    // MARK: Internal

    var body: some View {
        Form {
            Section {
                Text("privacy_statement_content")
                    .font(.body)
                    .multilineTextAlignment(.leading)
            } header: {
                Text("privacy_statement")
            }
            Section {
                HStack {
                    Text("crash_log")
                    Toggle("allow_collect_crash_log", isOn: $allowCollectCrashLog)
                }
                HStack {
                    Text("analytics")
                    Toggle("allow_collect_analytics", isOn: $allowCollectAnalytics)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Private

    @Default(.allowCrashLog) private var allowCollectCrashLog
    @Default(.allowAnalytics) private var allowCollectAnalytics
}

#Preview {
    PrivacyTab()
}
