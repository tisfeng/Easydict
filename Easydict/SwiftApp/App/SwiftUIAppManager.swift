//
//  SwiftUIAppManager.swift
//  Easydict
//
//  Created by Kyle on 2023/12/28.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

@objc(EasydictNewAppManager)
public final class SwiftUIAppManager: NSObject {
    @objc
    public static let shared = SwiftUIAppManager()

    override private init() { super.init() }

    private static var enableKey: String { kEnableBetaNewAppKey }

    /// 新的 MenuBarExtra 对齐 EZStatusItem & 可以放弃 macOS 13- 支持后全量
    @objc
    public var enable: Bool {
        UserDefaults.standard.bool(forKey: Self.enableKey)
    }
}
