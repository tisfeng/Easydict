//
//  PreferencesWindowController.swift
//  Easydict
//
//  Created by Kyle on 2023/10/28.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation
import MASPreferences
import AppKit

@objc(EZPreferencesWindowController)
public final class PreferencesWindowController: MASPreferencesWindowController {

    @objc public private(set) var isShowing = false

    @objc public static let shared: PreferencesWindowController = {
        let viewControllers = [
            EZSettingViewController(),
            EZServiceViewController(),
            EZDisableAutoSelectTextViewController(),
            EZPrivacyViewController(),
            EZAboutViewController(),
        ]
        let appName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? ""
        return PreferencesWindowController(viewControllers: viewControllers, title: appName)
    }()


    @objc public func show() {
        isShowing = true
        guard let window else {
            return
        }
        window.makeKeyAndOrderFront(nil)
        if !window.isKeyWindow {
            NSApp.activate(ignoringOtherApps: true)
        }
        window.center()
    }

    public override func windowWillClose(_ notification: Notification) {
        isShowing = false
    }
}
