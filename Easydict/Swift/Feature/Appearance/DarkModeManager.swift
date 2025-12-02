//
//  DarkModeManager.swift
//  Easydict
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Combine
import Foundation

// MARK: - Notification Extensions

extension Notification.Name {
    static let darkModeDidChange = Notification.Name("DarkModeDidChange")
}

// MARK: - DarkModeManager

@objcMembers
class DarkModeManager: NSObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    private override init() {
        super.init()
        setupNotificationObserver()
    }

    // MARK: - Deinitialization

    deinit {
        removeNotificationObserver()
    }

    // MARK: Internal

    // MARK: - Singleton

    static let shared = DarkModeManager()

    private(set) var systemDarkMode: Bool = false {
        didSet {
            NotificationCenter.default.post(
                name: .darkModeDidChange,
                object: nil,
                userInfo: ["isDark": systemDarkMode]
            )
        }
    }

    // MARK: - Public Methods

    func updateDarkMode(_ appearanceType: AppearanceType) {
        let isDarkMode = currentSystemDarkMode()

        switch appearanceType {
        case .dark:
            systemDarkMode = true
        case .light:
            systemDarkMode = false
        case .followSystem:
            systemDarkMode = isDarkMode
        }

        AppearanceHelper.shared.updateAppAppearance(appearanceType)
        logInfo("\(systemDarkMode ? "深色模式" : "浅色模式")")
    }

    func currentSystemDarkMode() -> Bool {
        if #available(macOS 10.14, *) {
            return NSApp.effectiveAppearance.bestMatch(from: [
                .darkAqua,
                .aqua,
            ]) == .darkAqua
        }
        return false
    }

    // MARK: Private

    private var notificationObserver: NSObjectProtocol?

    // MARK: - Private Methods

    private func setupNotificationObserver() {
        notificationObserver = DistributedNotificationCenter.default().addObserver(
            forName: .appleInterfaceThemeChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemThemeChanged()
        }
    }

    private func removeNotificationObserver() {
        if let observer = notificationObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    private func handleSystemThemeChanged() {
        updateDarkMode(Configuration.shared.appearance)
    }
}
