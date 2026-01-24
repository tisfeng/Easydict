//
//  AnalyticsService.swift
//  Easydict
//
//  Created by tisfeng on 2025/12/22.
//  Copyright © 2025 izual. All rights reserved.
//

import FirebaseAnalytics
import FirebaseCore
import Foundation
import Sentry

/// Provides analytics and crash logging utilities.
@objc(EZAnalyticsService)
@objcMembers
final class AnalyticsService: NSObject {
    // MARK: Internal

    /// Configures crash logging services in non-debug builds.
    @objc(setupCrashLogService)
    static func setupCrashService() {
        #if !DEBUG
        configureFirebaseIfNeeded()
        SentrySDK.start { options in
            options.dsn = SecretKeyManager.keyValues["sentryDSN"]
            options.debug = true
            options.tracesSampleRate = NSNumber(value: 0.1)
            options.swiftAsyncStacktraces = true
        }
        #endif
    }

    /// Enables or disables crash logging, and always disables it in debug builds.
    static func setCrashEnabled(_ enabled: Bool) {
        #if DEBUG
        SentrySDK.close()
        #else
        if enabled {
            setupCrashService()
        } else {
            SentrySDK.close()
        }
        #endif
    }

    /// Logs an analytics event with the given name and parameters.
    ///
    /// - Note: Event names must contain only letters, numbers, or underscores.
    /// - Parameters should use string keys and values that are compatible with analytics.
    @objc(logEventWithName:parameters:)
    static func logEvent(withName name: String, parameters: [String: Any]?) {
        guard MyConfiguration.shared.allowAnalytics else {
            return
        }

        #if !DEBUG
        Analytics.logEvent(name, parameters: parameters)
        #endif
    }

    /// Logs window appearance events.
    @objc(logWindowAppear:)
    static func logWindowAppear(_ windowType: EZWindowType) {
        let windowName = EZEnumTypes.windowName(windowType)
        let name = "show_\(windowName)"
        logEvent(withName: name, parameters: nil)
    }

    /// Logs query service usage for analytics.
    @objc(logQueryService:)
    static func logQueryService(_ service: QueryService) {
        let model = service.queryModel

        let textLengthRange = textLengthRange(model.queryText)
        let parameters: [String: Any] = [
            "serviceType": service.serviceType().rawValue,
            "actionType": model.actionType.rawValue,
            "from": model.queryFromLanguage.rawValue,
            "to": model.queryTargetLanguage.rawValue,
            "textLength": textLengthRange,
        ]
        logEvent(withName: "query_service", parameters: parameters)
    }

    /// Returns a human-readable text length range.
    static func textLengthRange(_ text: String) -> String {
        let length = text.utf16.count
        if length <= 10 {
            return "1-10"
        } else if length <= 50 {
            return "10-50"
        } else if length <= 200 {
            return "50-200"
        } else if length <= 1000 {
            return "200-1000"
        } else if length <= 5000 {
            return "1000-5000"
        } else {
            return "5000-∞"
        }
    }

    /// Logs basic app information for analytics.
    static func logAppInfo() {
        let version = DeviceSystemInfo.getSystemVersion()
        let parameters: [String: Any] = [
            "system_version": version,
        ]
        logEvent(withName: "app_info", parameters: parameters)
    }

    // MARK: Private

    private static let firebaseConfigurationToken: () = {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }()

    /// Ensures Firebase is configured only once.
    private static func configureFirebaseIfNeeded() {
        _ = firebaseConfigurationToken
    }
}
