//
//  DisableAutoSelectTextViewController.swift
//  Easydict
//
//  Created by Kyle on 2023/10/31.
//  Copyright © 2023 izual. All rights reserved.
//

import Settings
import SwiftUI

let DisableAutoSelectTextViewController: () -> SettingsPane = {
    let panelView = Settings.Pane(
        identifier: .init("DisableAutoSelectText"),
        title: NSLocalizedString("disabled_app_list", comment: ""),
        toolbarIcon: .disableBlue
    ) {
        DisableAutoSelectTextPanelView()
    }
    return Settings.PaneHostingController(pane: panelView)
}

struct DisableAutoSelectTextPanelView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(verbatim: "TODO")
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 30)
        }
        .frame(idealWidth: 500, idealHeight: 300)
    }
}

#Preview {
    DisableAutoSelectTextPanelView()
}
