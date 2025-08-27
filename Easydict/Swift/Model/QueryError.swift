//
//  QueryError.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import Vapor

// MARK: - QueryError

@objc(EZQueryError)
@objcMembers
public class QueryError: NSError, LocalizedError, AbortError, @unchecked Sendable {
    // MARK: Lifecycle

    public init(
        type: ErrorType,
        message: String? = nil,
        errorDataMessage: String? = nil
    ) {
        self.type = type
        self.message = message
        self.errorDataMessage = errorDataMessage

        var userInfo: [String: Any] = [:]
        if let message = message {
            userInfo[NSLocalizedDescriptionKey] = message
        }

        super.init(domain: "com.izual.Easydict.QueryError", code: type.rawValue, userInfo: userInfo)
    }

    @available(*, deprecated)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    // enum Int for objc

    @objc(EZQueryErrorType)
    public enum ErrorType: Int, LocalizedError {
        case unknown
        case api
        case parameter
        case appleScript
        case unsupportedLanguage
        case missingSecretKey
        case noResult
        case timeout
        case unsupportedQueryType // If query dict type but the service does not support it
        case unsupportedServiceType // HTTP request serviceType not supported

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .unknown:
                String(localized: "unknown_error")
            case .api:
                String(localized: "api_error")
            case .parameter:
                String(localized: "parameter_error")
            case .appleScript:
                String(localized: "apple_script_error")
            case .unsupportedLanguage:
                String(localized: "unsupported_language_error")
            case .missingSecretKey:
                String(localized: "missing_secret_key_error")
            case .noResult:
                String(localized: "no_result_error")
            case .timeout:
                String(localized: "timeout_error")
            case .unsupportedQueryType:
                String(localized: "unsupported_query_type_error")
            case .unsupportedServiceType:
                String(localized: "unsupported_service_type_error")
            }
        }
    }

    /// Timeout error
    public static var timeoutError: QueryError {
        .error(type: .timeout)
    }

    public override var localizedDescription: String {
        errorDescription ?? ""
    }

    public override var description: String {
        errorDescription ?? ""
    }

    public let type: ErrorType
    public var message: String?
    public var errorDataMessage: String?

    public var errorDescription: String? {
        var errorString = ""

        // Add zero-width space to fix emoji rendering issue
        let queryFailed = "\u{200B}" + String(localized: "query_failed")
        errorString += "\(queryFailed), "

        errorString += "\(type.localizedDescription)"

        if let message, !message.isEmpty {
            errorString += ": \(message)"
        }

        if let errorDataMessage, !errorDataMessage.isEmpty {
            errorString += "\n\n\(errorDataMessage)"
        }

        return errorString
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

    public static func unsupportedLanguageError(service: QueryService) -> QueryError {
        let to = service.languageCode(forLanguage: service.queryModel.queryTargetLanguage)
        var unsupportLanguage = service.queryModel.queryFromLanguage
        if to == nil {
            unsupportLanguage = service.queryModel.queryTargetLanguage
        }

        let showUnsupportLanguage = EZLanguageManager.shared().showingLanguageName(
            unsupportLanguage
        )

        return .error(type: .unsupportedLanguage, message: showUnsupportLanguage)
    }

    /// Create a QueryError from any error type
    /// - Parameter error: The source error
    /// - Returns: If error is nil, returns nil
    ///           If error is already a QueryError, returns it directly
    ///           Otherwise, creates a new QueryError with the error's localized description
    public static func queryError(
        from error: Error?,
        type: ErrorType = .api
    )
        -> QueryError? {
        if let error {
            if let queryError = error as? QueryError {
                return queryError
            } else {
                return .init(type: type, errorDataMessage: String(describing: error))
            }
        } else {
            return nil
        }
    }

    public static func queryError(from error: Error?) -> QueryError? {
        queryError(from: error, type: .api)
    }
}

// MARK: - Vapor AbortError

extension QueryError {
    public var status: HTTPResponseStatus {
        .badRequest
    }

    public var reason: String {
        errorDescription ?? ""
    }
}
