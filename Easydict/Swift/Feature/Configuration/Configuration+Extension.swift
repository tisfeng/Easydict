//
//  Configuration+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/24.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: Window Frame

extension Configuration {
    func windowFrameWithType(_ windowType: EZWindowType) -> CGRect {
        Defaults[.windowFrame(for: windowType)]
    }

    func setWindowFrame(_ frame: CGRect, windowType: EZWindowType) {
        Defaults[.windowFrame(for: windowType)] = frame
    }
}

// MARK: Intelligent Query Text Type of Service

extension Configuration {
    func setIntelligentQueryTextType(_ queryTextType: EZQueryTextType, serviceType: ServiceType) {
        Defaults[.intelligentQueryTextType(for: serviceType)] = queryTextType
    }

    func intelligentQueryTextTypeForServiceType(_ serviceType: ServiceType) -> EZQueryTextType {
        Defaults[.intelligentQueryTextType(for: serviceType)]
    }
}

// MARK: Intelligent Query Text Type of Service

extension Configuration {
    func setQueryTextType(_ queryTextType: EZQueryTextType, serviceType: ServiceType) {
        Defaults[.queryTextType(for: serviceType)] = queryTextType
    }

    func queryTextTypeForServiceType(_ serviceType: ServiceType) -> EZQueryTextType {
        Defaults[.queryTextType(for: serviceType)]
    }
}

// MARK: Intelligent Query Mode

extension Configuration {
    func setIntelligentQueryMode(_ enabled: Bool, windowType: EZWindowType) {
        let key = EZConstKey.constkey("IntelligentQueryMode", windowType: windowType)
        let stringValue = "\(enabled)"
        UserDefaults.standard.set(stringValue, forKey: key)

        let parameters =
            [
                "enabled": enabled,
                "window_type": windowType.rawValue,
            ] as [String: Any]

        AnalyticsService.logEvent(withName: "intelligent_query_mode", parameters: parameters)
    }

    func intelligentQueryModeForWindowType(_ windowType: EZWindowType) -> Bool {
        let key = EZConstKey.constkey("IntelligentQueryMode", windowType: windowType)
        return UserDefaults.standard.bool(forKey: key)
    }
}

// MARK: Window Configuration

extension Configuration {
    func showInputTextField(key: WindowConfigurationKey, windowType: EZWindowType) -> Bool {
        Defaults[windowConfigurationKey(key, windowType: windowType, defaultValue: true)]
    }
}
