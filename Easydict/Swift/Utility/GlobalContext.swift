//
//  GlobalContext.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/25.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import Sparkle

@objcMembers
class GlobalContext: NSObject {
    // MARK: Lifecycle

    private override init() {
        self.updaterHelper = SPUUpdaterHelper()
        self.userDriverHelper = SPUUserDriverHelper()
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: updaterHelper,
            userDriverDelegate: userDriverHelper
        )

        super.init()

        reloadLLMServicesSubscribers()
    }

    // MARK: Internal

    class SPUUpdaterHelper: NSObject, SPUUpdaterDelegate {
        func feedURLString(for _: SPUUpdater) -> String? {
            var feedURLString =
                "https://raw.githubusercontent.com/tisfeng/Easydict/main/appcast.xml"
            #if DEBUG
            feedURLString = "http://localhost:8000/appcast.xml"
            #endif
            return feedURLString
        }
    }

    class SPUUserDriverHelper: NSObject, SPUStandardUserDriverDelegate {
        var supportsGentleScheduledUpdateReminders: Bool {
            true
        }
    }

    static let shared = GlobalContext()

    let updaterController: SPUStandardUpdaterController

    // refresh subscribed services after duplicate service
    func reloadLLMServicesSubscribers() {
        logInfo("reloadLLMServicesSubscribers")

        for service in services {
            if let llmService = service as? StreamService {
                llmService.cancelSubscribers()
            }
        }
        let allServiceTypes = LocalStorage.shared().allServiceTypes(EZWindowType.main)
        services = QueryServiceFactory.shared.services(fromTypes: allServiceTypes)
        for service in services {
            if let llmService = service as? StreamService {
                llmService.setupSubscribers()
            }
        }
    }

    // MARK: Private

    private let updaterHelper: SPUUpdaterHelper
    private let userDriverHelper: SPUUserDriverHelper

    // TODO: This code is not good, we should improve it later.

    /**
     We need all services to observe llm serivce subscribers for query windows and settings, `services` should keep a strong reference and do not deallocate during the app lifecycle.

     When notify a service configuration changed, it will init a new service, this is bad.

     For some strange reason, the old service can not be deallocated, this will cause a memory leak, and we also need to cancel old services subscribers.
     */
    private var services: [QueryService] = []
}
