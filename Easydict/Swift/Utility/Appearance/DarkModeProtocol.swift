//
//  DarkModeProtocol.swift
//  Easydict
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
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
        guard lightHandler != nil || darkHandler != nil else {
            return
        }

        let observerStore = darkModeObserverStore()
        observerStore.appendHandler { isDark in
            if isDark {
                darkHandler?()
            } else {
                lightHandler?()
            }
        }
    }

    /// Remove all dark mode observers for this object
    func removeDarkModeObservers() {
        guard let observerStore = objc_getAssociatedObject(self, &darkModeObserverStoreKey) as? DarkModeObserverStore
        else {
            return
        }

        observerStore.removeAllHandlers()
        objc_setAssociatedObject(self, &darkModeObserverStoreKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Returns the shared dark mode observer store for the receiver.
    private func darkModeObserverStore() -> DarkModeObserverStore {
        if let observerStore = objc_getAssociatedObject(self, &darkModeObserverStoreKey) as? DarkModeObserverStore {
            return observerStore
        }

        let observerStore = DarkModeObserverStore()
        objc_setAssociatedObject(self, &darkModeObserverStoreKey, observerStore, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return observerStore
    }
}

// MARK: - DarkModeObserverStore

/// Stores dark mode handlers for a single owner and dispatches updates on the main thread.
private final class DarkModeObserverStore: NSObject {
    // MARK: Lifecycle

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDarkModeDidChange(_:)),
            name: .appDarkModeDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Internal

    /// Appends a dark mode handler to the store.
    func appendHandler(_ handler: @escaping DarkModeHandler) {
        handlers.append(handler)
    }

    /// Removes all stored handlers.
    func removeAllHandlers() {
        handlers.removeAll()
    }

    // MARK: Private

    private var handlers: [DarkModeHandler] = []

    @objc
    private func handleDarkModeDidChange(_ notification: Notification) {
        guard let isDark = notification.userInfo?[UserInfoKey.isDark] as? Bool else {
            return
        }

        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.dispatchHandlers(isDark: isDark)
            }
            return
        }

        dispatchHandlers(isDark: isDark)
    }

    private func dispatchHandlers(isDark: Bool) {
        handlers.forEach { $0(isDark) }
    }
}

private typealias DarkModeHandler = (Bool) -> ()
private var darkModeObserverStoreKey: UInt8 = 0
