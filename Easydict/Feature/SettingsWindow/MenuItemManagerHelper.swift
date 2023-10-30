//
//  MenuItemManagerHelper.swift
//  Easydict
//
//  Created by Kyle on 2023/10/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation
import Settings

/// A Swift wrapper before we migrate EZMenuItemManager to Swift
@objc(EZMenuItemManagerHelper)
public class MenuItemManagerHelper: NSObject {
    @objc public static let shared = MenuItemManagerHelper()

    private lazy var settingsWindowController = SettingsWindowController(
        panes: [
            DisableAutoSelectTextViewController(),
            PrivacyViewController(),
            AboutViewController(),
        ]
    )

    @objc func show() {
        settingsWindowController.show()
    }
}
