//
//  ConfigurationSchemeActionCoordinator.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Combine
import Foundation

// MARK: - ConfigurationSchemeAction

enum ConfigurationSchemeAction: Int {
    case none
    case encryptedExport
    case reset
}

// MARK: - ConfigurationSchemeActionCoordinator

/// Moves destructive or file-writing URL Scheme requests into a user-confirmed settings flow.
@objc(EZConfigurationSchemeActionCoordinator)
final class ConfigurationSchemeActionCoordinator: NSObject, ObservableObject {
    // MARK: Internal

    @objc static let shared = ConfigurationSchemeActionCoordinator()

    @Published private(set) var pendingAction = ConfigurationSchemeAction.none

    @objc
    func requestEncryptedExport() {
        request(.encryptedExport)
    }

    @objc
    func requestResetConfirmation() {
        request(.reset)
    }

    func consume(_ action: ConfigurationSchemeAction) {
        guard pendingAction == action else { return }
        pendingAction = .none
    }

    // MARK: Private

    private func request(_ action: ConfigurationSchemeAction) {
        DispatchQueue.main.async {
            self.pendingAction = action
            NotificationCenter.default.post(name: .openSettings, object: nil)
        }
    }
}
