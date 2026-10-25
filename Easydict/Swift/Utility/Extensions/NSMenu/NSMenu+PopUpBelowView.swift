//
//  NSMenu+PopUp.swift
//  Easydict
//
//  Created by tisfeng on 2024/3/22.
//  Copyright © 2024 izual. All rights reserved.
//

import AppKit
import Foundation

@objc
extension NSMenu {
    @MainActor
    func popUp(belowView view: NSView) {
        I18nHelper.shared.applyInterfaceLayoutDirection(to: self)
        let isRTL = I18nHelper.shared.interfaceLayoutDirection == .rightToLeft
        view.userInterfaceLayoutDirection = I18nHelper.shared.interfaceLayoutDirection
        let point = CGPoint(x: isRTL ? view.bounds.width : 0, y: view.frame.height + 8)
        popUp(positioning: nil, at: point, in: view)
    }
}
