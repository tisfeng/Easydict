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

    /// Remove all dark mode observers for this object
    func removeDarkModeObservers()
}

// MARK: - Default Implementation

extension DarkModeCapable where Self: NSObject {
    func setupDarkModeObserver(
        lightHandler: (() -> ())? = nil,
        darkHandler: (() -> ())? = nil
    ) {
        let cancellable = NotificationCenter.default.publisher(for: .appDarkModeDidChange)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                guard let isDark = notification.userInfo?[NotificationUserInfoKey.isDark] as? Bool else { return }

                if isDark {
                    darkHandler?()
                } else {
                    lightHandler?()
                }
            }

        // Get or create cancellables array for this object
        if var cancellables = objc_getAssociatedObject(self, &cancellablesKey) as? [AnyCancellable] {
            // Add new cancellable to existing array
            cancellables.append(cancellable)
            objc_setAssociatedObject(self, &cancellablesKey, cancellables, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            // Create new array with first cancellable
            objc_setAssociatedObject(self, &cancellablesKey, [cancellable], .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            // Setup automatic cleanup on first observer
            setupAutomaticDarkModeCleanup()
        }
    }

    /// Remove all dark mode observers for this object
    func removeDarkModeObservers() {
        if let cancellables = objc_getAssociatedObject(self, &cancellablesKey) as? [AnyCancellable] {
            cancellables.forEach { $0.cancel() }
            objc_setAssociatedObject(self, &cancellablesKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Automatically clean up observers when object is deallocated
    func setupAutomaticDarkModeCleanup() {
        // This will be called when the object is deallocated
        objc_setAssociatedObject(self, &cleanupObserverKey, DarkModeCleanupObserver { [weak self] in
            self?.removeDarkModeObservers()
        }, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - DarkModeCleanupObserver

// Helper class to trigger cleanup on deallocation
private class DarkModeCleanupObserver: NSObject {
    // MARK: Lifecycle

    init(cleanup: @escaping () -> ()) {
        self.cleanup = cleanup
        super.init()
    }

    deinit {
        cleanup()
    }

    // MARK: Private

    private let cleanup: () -> ()
}

private var cancellablesKey: UInt8 = 0
private var cleanupObserverKey: UInt8 = 1
