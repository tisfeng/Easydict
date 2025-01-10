//
//  QueryError.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - QueryError

@objc(EZQueryError)
@objcMembers
public class QueryError: NSError, LocalizedError, @unchecked Sendable {
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    // enum Int for objc

    @objc(EZQueryErrorType)
    public enum ErrorType: Int {
        case unknown
        case api
        case parameter
        case appleScript
        case unsupportedLanguage
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
            case .unsupportedLanguage:
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

    /// Timeout error
    public static var timeoutError: QueryError {
        .error(type: .timeout)
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

    public override var localizedDescription: String {
        errorDescription ?? ""
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

    // NSError *EZQueryUnsupportedLanguageError(EZQueryService *service) {
    //    NSString *to = [service languageCodeForLanguage:service.queryModel.queryTargetLanguage];
    //    EZLanguage unsupportLanguage = service.queryModel.queryFromLanguage;
    //    if (!to) {
    //        unsupportLanguage = service.queryModel.queryTargetLanguage;
    //    }
    //
    //    NSString *showUnsupportLanguage = [EZLanguageManager.shared showingLanguageName:unsupportLanguage];
    //    NSError *error = [EZQueryError errorWithType:EZQueryErrorTypeUnsupportedLanguage message:showUnsupportLanguage];
    //    return error;
    // }

    public static func unsupportedLanguageError(service: QueryService)
        -> QueryError {
        let to = service.languageCode(forLanguage: service.queryModel.queryTargetLanguage)
        var unsupportLanguage = service.queryModel.queryFromLanguage
        if to == nil {
            unsupportLanguage = service.queryModel.queryTargetLanguage
        }

        let showUnsupportLanguage = EZLanguageManager.shared().showingLanguageName(
            unsupportLanguage
        )

        return .error(
            type: .unsupportedLanguage,
            message: showUnsupportLanguage
        )
    }
}
