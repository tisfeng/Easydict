//
//  QueryError.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - QueryError

@objcMembers
public class QueryError: NSObject, LocalizedError, @unchecked Sendable {
    // MARK: Lifecycle

    public init(
        type: ErrorType,
        message: String? = nil,
        errorDataMessage: String? = nil
    ) {
        self.type = type
        self.message = message
        self.errorDataMessage = errorDataMessage
        super.init()
    }

    // MARK: Public

    // enum Int for objc

    @objc
    public enum ErrorType: Int {
        case unknown
        case api
        case parameter
        case appleScript
        case unsupported
        case missingSecretKey
        case noResult
        case timeout

        // MARK: Internal

        var localizationKey: String {
            switch self {
            case .unknown:
                "unknown_error"
            case .api:
                "api_error"
            case .parameter:
                "parameter_error"
            case .appleScript:
                "apple_script_error"
            case .unsupported:
                "unsupported_language_error"
            case .missingSecretKey:
                "missing_secret_key_error"
            case .noResult:
                "no_result_error"
            case .timeout:
                "timeout_error"
            }
        }

        var localizedString: String {
            NSLocalizedString(localizationKey, comment: "")
        }
    }

    public let type: ErrorType
    public var message: String?
    public var errorDataMessage: String?

    public var errorDescription: String? {
        var errorString = ""

        // Add zero-width space to fix emoji rendering issue
//        let queryFailed = "\u{200B}" + String(localized: "query_failed")
//        errorString += "\(queryFailed), "

        errorString += "\(type.localizedString)"

        if let message, !message.isEmpty {
            errorString += ": \(message)"
        }

        if let errorDataMessage, !errorDataMessage.isEmpty {
            errorString += "\n\(errorDataMessage)"
        }

        return errorString
    }

    public override var description: String {
        "\(type.rawValue): \(message ?? "")"
    }

    public static func error(type: ErrorType) -> QueryError {
        .init(type: type)
    }

    public static func error(type: ErrorType, message: String? = nil) -> QueryError {
        .init(type: type, message: message)
    }

    public static func error(
        type: ErrorType,
        message: String? = nil,
        errorDataMessage: String? = nil
    )
        -> QueryError {
        .init(type: type, message: message, errorDataMessage: errorDataMessage)
    }
}
