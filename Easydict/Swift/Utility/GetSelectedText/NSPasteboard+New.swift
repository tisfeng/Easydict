//
//  Clipboards.swift
//  SecureYourClipboard
//
//  Created by lixindong on 2024/4/24.
//

import Foundation
import AppKit

extension NSPasteboard {
    // 处理选中的文字
    static let selected = NSPasteboard(name: .init("selected"))
    
    // 处理安全复制的文字
    static let safeCopy = NSPasteboard(name: .init("safeCopy"))
}

// 设置文字
extension NSPasteboard {
    func setString(_ string: String?) {
        clearContents()
        if let string {
            setString(string, forType: .string)
        }
    }
    
    func string() -> String? {
        self.string(forType: .string)
    }
}
