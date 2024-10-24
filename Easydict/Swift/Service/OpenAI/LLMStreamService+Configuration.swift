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
        logInfo("setup subscribers: \(self), windowType: \(windowType.rawValue)")

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

    func cancelSubscribers() {
        logInfo("cancel subscribers: \(self), windowType: \(windowType.rawValue)")
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
        notifyServiceConfigurationChanged(autoQuery: true)
    }

    func supportedModelsTextDidChanged(_ newSupportedModels: String) {
        supportedModels = newSupportedModels

        if validModels.isEmpty {
            model = ""
        } else if !validModels.contains(model) {
            model = validModels[0]
        }
    }

    func notifyServiceConfigurationChanged(autoQuery: Bool = false) {
        logInfo("service config changed: \(serviceType().rawValue), windowType: \(windowType.rawValue)")

        NotificationCenter.default.postServiceUpdateNotification(
            serviceType: serviceTypeWithUniqueIdentifier(),
            windowType: windowType,
            autoQuery: autoQuery
        )
    }

    func stringDefaultsKey(_ key: ServiceConfigurationKey) -> Defaults.Key<String> {
        stringDefaultsKey(key, defaultValue: "")
    }

    func stringDefaultsKey(_ key: ServiceConfigurationKey, defaultValue: String) -> Defaults.Key<String> {
        defaultsKey(key, serviceType: serviceType(), id: uuid, defaultValue: defaultValue)
    }

    func boolDefaultsKey(_ key: ServiceConfigurationKey, defaultValue: Bool) -> Defaults.Key<Bool> {
        defaultsKey(key, serviceType: serviceType(), id: uuid, defaultValue: defaultValue)
    }

    func serviceDefaultsKey<T>(_ key: ServiceConfigurationKey, defaultValue: T) -> Defaults.Key<T> {
        defaultsKey(key, serviceType: serviceType(), id: uuid, defaultValue: defaultValue)
    }
}
