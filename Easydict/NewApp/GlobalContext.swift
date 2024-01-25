//
//  GlobalContext.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/25.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import Sparkle

@objc class GlobalContext: NSObject {
    static let updaterController: SPUStandardUpdaterController = {
        class SPUUpdaterHelper: NSObject, SPUUpdaterDelegate {
            func feedURLString(for _: SPUUpdater) -> String? {
                var feedURLString = "https://raw.githubusercontent.com/tisfeng/Easydict/main/appcast.xml"
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
        let userDriverHelper = SPUUserDriverHelper()
        let upadterHelper = SPUUpdaterHelper()
        // 参考 https://sparkle-project.org/documentation/programmatic-setup/
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        return SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: upadterHelper,
            userDriverDelegate: userDriverHelper
        )
    }()

    @objc class func getUpdaterController() -> SPUStandardUpdaterController {
        updaterController
    }
}
