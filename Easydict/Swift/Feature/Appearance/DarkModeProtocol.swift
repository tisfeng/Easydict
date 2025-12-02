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
        NotificationCenter.default.publisher(for: .darkModeDidChange)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                guard let isDark = notification.userInfo?["isDark"] as? Bool else { return }

                if isDark {
                    darkHandler?()
                } else {
                    lightHandler?()
                }
            }
            .store(in: &associatedCancellables)
    }

    // Associated object for storing cancellables
    private var associatedCancellables: Set<AnyCancellable> {
        get {
            objc_getAssociatedObject(self, &cancellablesKey) as? Set<AnyCancellable> ?? Set<AnyCancellable>()
        }
        set {
            objc_setAssociatedObject(self, &cancellablesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private var cancellablesKey: UInt8 = 0
