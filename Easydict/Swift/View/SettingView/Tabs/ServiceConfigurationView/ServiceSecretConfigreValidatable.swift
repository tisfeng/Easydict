//
//  ServiceSecretConfigreValidatable.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/30.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - ServiceSecretConfigreValidatable

protocol ServiceSecretConfigreValidatable {
    func validate() async -> QueryResult
}

// MARK: - QueryService + ServiceSecretConfigreValidatable

extension QueryService: ServiceSecretConfigreValidatable {
    func validate() async -> QueryResult {
        resetServiceResult()

        /**
         To reduce output text, save cost, a simple translation example is enough.

         1. use zh -> en to avoid analyze English sentence.
         2. if Chinese text length > 5, it won't query dict.
         */

        let text = "曾经沧海难为水"
        var latestResult = result ?? QueryResult()

        do {
            for try await result in translateStream(text, from: .simplifiedChinese, to: .english) {
                latestResult = result
            }
        } catch {
            latestResult = result ?? latestResult
            if latestResult.error == nil {
                latestResult.error = QueryError.queryError(from: error)
            }
        }

        return latestResult
    }
}

// MARK: - ServiceSecretConfigreDuplicatable

protocol ServiceSecretConfigreDuplicatable {
    func duplicate()
    func remove()
}

extension ServiceSecretConfigreDuplicatable {
    func duplicate() {}
    func remove() {}
}

// MARK: - QueryService + ServiceSecretConfigreDuplicatable

extension QueryService: ServiceSecretConfigreDuplicatable {
    func duplicate() {
        let uuid = UUID().uuidString
        let newServiceType = "\(serviceType().rawValue)#\(uuid)"
        guard let newService = QueryServiceFactory.shared.service(withTypeId: newServiceType) else {
            return
        }
        newService.enabled = false
        newService.resetServiceResult()
        for winType in [EZWindowType.fixed, EZWindowType.main, EZWindowType.mini] {
            var allServiceTypes = LocalStorage.shared().allServiceTypes(winType)
            allServiceTypes.append(newServiceType)
            newService.windowType = winType
            LocalStorage.shared().setService(newService, windowType: winType)
            LocalStorage.shared().setAllServiceTypes(allServiceTypes, windowType: winType)
            NotificationCenter.default.postServiceUpdateNotification(windowType: winType)
        }
        GlobalContext.shared.reloadLLMServicesSubscribers()
    }

    func remove() {
        for winType in [EZWindowType.fixed, EZWindowType.main, EZWindowType.mini] {
            let allServiceTypes = LocalStorage.shared().allServiceTypes(winType)
                .filter { $0 != serviceTypeWithUniqueIdentifier() }
            LocalStorage.shared().setAllServiceTypes(allServiceTypes, windowType: winType)
            NotificationCenter.default.postServiceUpdateNotification(windowType: winType)
        }
        GlobalContext.shared.reloadLLMServicesSubscribers()
    }
}
