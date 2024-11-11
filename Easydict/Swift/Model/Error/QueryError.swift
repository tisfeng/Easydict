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
public class QueryError: NSError, LocalizedError, @unchecked Sendable {
    // MARK: Lifecycle

    public init(type: ErrorType, code: Int = -1, message: String) {
        self.type = type
        self.message = message
        let userInfo = [NSLocalizedDescriptionKey: message]
        super.init(domain: Bundle.main.bundleIdentifier!, code: code, userInfo: userInfo)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public enum ErrorType: String {
        case unknown = "Unknown Error"
        case api = "API Error"
        case parameter = "Parameter Error"
        case timeout = "Timeout Error"
        case appleScript = "AppleScript Execution Error"
        case unsupported = "Unsupported Language"
        case missingSecretKey = "Missing Secret Key"
    }

    public let type: ErrorType
    public var message: String

    public override var localizedDescription: String {
        description
    }

    public override var description: String {
        "\(type.rawValue): \(message)"
    }

    public static func error(type: ErrorType, code: Int = -1, message: String) -> QueryError {
        QueryError(type: type, code: code, message: message)
    }
}
