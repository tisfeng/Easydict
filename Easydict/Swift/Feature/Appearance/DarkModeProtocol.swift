//
//  DarkModeProtocol.swift
//  Easydict
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Combine
import Foundation

// MARK: - DarkModeCapable

protocol DarkModeCapable: AnyObject {
    func setupDarkModeObserver(
        lightHandler: (() -> ())?,
        darkHandler: (() -> ())?
    )
}

// MARK: - Default Implementation

extension DarkModeCapable where Self: NSObject {
    func setupDarkModeObserver(
        lightHandler: (() -> ())? = nil,
        darkHandler: (() -> ())? = nil
    ) {
        let cancellable = NotificationCenter.default.publisher(for: .darkModeDidChange)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                guard let isDark = notification.userInfo?["isDark"] as? Bool else { return }

                if isDark {
                    darkHandler?()
                } else {
                    lightHandler?()
                }
            }

        // Store the cancellable using a simple approach
        if let existingCancellable = objc_getAssociatedObject(self, &cancellablesKey) as? AnyCancellable {
            existingCancellable.cancel()
        }
        objc_setAssociatedObject(self, &cancellablesKey, cancellable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private var cancellablesKey: UInt8 = 0
