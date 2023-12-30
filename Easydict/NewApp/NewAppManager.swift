//
//  NewAppManager.swift
//  Easydict
//
//  Created by Kyle on 2023/12/28.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

@objc(EasydictNewAppManager)
public final class NewAppManager: NSObject {
    @objc
    public static let shared = NewAppManager()

    override private init() { super.init() }

    private static var enableKey: String { kEnableBetaNewAppKey }

    /// 新的 MenuBarExtra 对齐 EZStatusItem & 可以放弃 macOS 13- 支持后全量
    @objc
    public var enable: Bool {
        UserDefaults.standard.bool(forKey: Self.enableKey)
    }

    @objc
    public var showEnableToggleUI: Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }
}
