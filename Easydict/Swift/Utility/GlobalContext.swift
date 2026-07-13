//
//  GlobalContext.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/25.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
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

    /// Sparkle Updater Helpers
    /// https://sparkle-project.org/documentation/publishing/#publishing-an-update

    class SPUUpdaterHelper: NSObject, SPUUpdaterDelegate {
        func allowedChannels(for updater: SPUUpdater) -> Set<String> {
            Defaults[.includeBetaUpdates] ? Set(["beta"]) : []
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
            service.cancelSubscribers()
        }
        let storage = LocalStorage.shared()
        let streamServiceTypes = storage.allServiceTypes(EZWindowType.main)
            .filter { QueryServiceFactory.shared.isStreamService(typeIdIfHave: $0) }
        services = streamServiceTypes.compactMap {
            storage.service($0, windowType: EZWindowType.main) as? StreamService
        }
        for service in services {
            service.setupSubscribers()
        }
    }

    // MARK: Private

    private let updaterHelper: SPUUpdaterHelper
    private let userDriverHelper: SPUUserDriverHelper

    // TODO: This code is not good, we should improve it later.

    /**
     We need stream services to observe LLM service subscribers for query
     windows and settings. `services` should keep a strong reference and not
     deallocate during the app lifecycle.

     Configuration notifications currently create new service instances.
     Cancel old subscribers before replacing services because old instances may
     be retained elsewhere.
     */
    private var services: [StreamService] = []
}
