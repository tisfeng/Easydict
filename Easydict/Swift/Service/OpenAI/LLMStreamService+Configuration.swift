//
//  LLMStreamService+Configuation.swift
//  Easydict
//
//  Created by tisfeng on 2024/6/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

extension LLMStreamService {
    func setupSubscribers() {
        Defaults.publisher(nameKey, options: [])
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                self?.notifyServiceConfigurationChanged()
            }
            .store(in: &cancellables)

        Defaults.publisher(modelKey, options: [])
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                self?.modelDidChanged($0.newValue)
            }
            .store(in: &cancellables)

        Defaults.publisher(supportedModelsKey, options: [])
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                self?.supportedModelsTextDidChanged($0.newValue)
            }
            .store(in: &cancellables)
    }

    func invalidate() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    func modelDidChanged(_ newModel: String) {
        model = newModel

        // Handle some special cases
        if !validModels.contains(newModel) {
            if newModel.isEmpty {
                supportedModels = ""
            } else {
                if supportedModels.isEmpty {
                    supportedModels = newModel
                } else {
                    supportedModels = "\(newModel), " + supportedModels
                }
            }
        }
        notifyServiceConfigurationChanged()
    }

    func supportedModelsTextDidChanged(_ newSupportedModels: String) {
        supportedModels = newSupportedModels

        if validModels.isEmpty {
            model = ""
        } else if !validModels.contains(model) {
            model = validModels[0]
        }
    }

    func notifyServiceConfigurationChanged() {
        objectWillChange.send()

        logInfo("service config changed: \(serviceType().rawValue)")

        let userInfo: [String: Any] = [
            EZWindowTypeKey: windowType.rawValue,
            EZServiceTypeKey: serviceType().rawValue,
        ]
        let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }

    func stringDefaultsKey(_ key: StoredKey) -> Defaults.Key<String> {
        stringDefaultsKey(key, defaultValue: "")
    }

    func stringDefaultsKey(_ key: StoredKey, defaultValue: String) -> Defaults.Key<String> {
        defaultsKey(key, serviceType: serviceType(), defaultValue: defaultValue)
    }

    func serviceDefaultsKey<T>(_ key: StoredKey, defaultValue: T) -> Defaults.Key<T> {
        defaultsKey(key, serviceType: serviceType(), defaultValue: defaultValue)
    }

    func serviceDefaultsKey<T>(_ key: StoredKey) -> Defaults.Key<T?> {
        defaultsKey(key, serviceType: serviceType())
    }
}
