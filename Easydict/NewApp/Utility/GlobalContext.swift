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
    static let shared = GlobalContext()

    let updaterController: SPUStandardUpdaterController
    let updaterHelper: SPUUpdaterHelper
    let userDriverHelper: SPUUserDriverHelper

    override init() {
        updaterHelper = SPUUpdaterHelper()
        userDriverHelper = SPUUserDriverHelper()

        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: updaterHelper, userDriverDelegate: userDriverHelper)
    }

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
}
