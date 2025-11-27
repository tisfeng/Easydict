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
    func popUp(belowView view: NSView) {
        let point = CGPoint(x: 0, y: view.frame.height + 8)
        popUp(positioning: nil, at: point, in: view)
    }
}
