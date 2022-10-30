// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2019, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

#if SWIFT_PACKAGE
import CocoaLumberjack
import CocoaLumberjackSwiftSupport
#endif

extension DDLogFlag {
    public static func from(_ logLevel: DDLogLevel) -> DDLogFlag {
        return DDLogFlag(rawValue: logLevel.rawValue)
    }

	public init(_ logLevel: DDLogLevel) {
        self = DDLogFlag(rawValue: logLevel.rawValue)
	}

    /// Returns the log level, or the lowest equivalent.
    public func toLogLevel() -> DDLogLevel {
        if let ourValid = DDLogLevel(rawValue: rawValue) {
            return ourValid
        } else {
            if contains(.verbose) {
                return .verbose
            } else if contains(.debug) {
                return .debug
            } else if contains(.info) {
                return .info
            } else if contains(.warning) {
                return .warning
            } else if contains(.error) {
                return .error
            } else {
                return .off
            }
        }
    }
}

/// The log level that can dynamically limit log messages (vs. the static DDDefaultLogLevel). This log level will only be checked, if the message passes the `DDDefaultLogLevel`.
public var dynamicLogLevel = DDLogLevel.all

/// Resets the `dynamicLogLevel` to `.all`.
/// - SeeAlso: `dynamicLogLevel`
@inlinable
public func resetDynamicLogLevel() {
    dynamicLogLevel = .all
}

@available(*, deprecated, message: "Please use dynamicLogLevel", renamed: "dynamicLogLevel")
public var defaultDebugLevel: DDLogLevel {
    get {
        return dynamicLogLevel
    }
    set {
        dynamicLogLevel = newValue
    }
}

@available(*, deprecated, message: "Please use resetDynamicLogLevel", renamed: "resetDynamicLogLevel")
public func resetDefaultDebugLevel() {
    resetDynamicLogLevel()
}

/// If `true`, all logs (except errors) are logged asynchronously by default.
public var asyncLoggingEnabled = true

@inlinable
public func _DDLogMessage(_ message: @autoclosure () -> String,
                          level: DDLogLevel,
                          flag: DDLogFlag,
                          context: Int,
                          file: StaticString,
                          function: StaticString,
                          line: UInt,
                          tag: Any?,
                          asynchronous: Bool,
                          ddlog: DDLog) {
    // The `dynamicLogLevel` will always be checked here (instead of being passed in).
    // We cannot "mix" it with the `DDDefaultLogLevel`, because otherwise the compiler won't strip strings that are not logged.
    if level.rawValue & flag.rawValue != 0 && dynamicLogLevel.rawValue & flag.rawValue != 0 {
        // Tell the DDLogMessage constructor to copy the C strings that get passed to it.
        let logMessage = DDLogMessage(message: message(),
                                      level: level,
                                      flag: flag,
                                      context: context,
                                      file: String(describing: file),
                                      function: String(describing: function),
                                      line: line,
                                      tag: tag,
                                      options: [.copyFile, .copyFunction],
                                      timestamp: nil)
        ddlog.log(asynchronous: asynchronous, message: logMessage)
    }
}

@inlinable
public func DDLogDebug(_ message: @autoclosure () -> String,
                       level: DDLogLevel = DDDefaultLogLevel,
                       context: Int = 0,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line,
                       tag: Any? = nil,
                       asynchronous async: Bool = asyncLoggingEnabled,
                       ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(), level: level, flag: .debug, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

@inlinable
public func DDLogInfo(_ message: @autoclosure () -> String,
                      level: DDLogLevel = DDDefaultLogLevel,
                      context: Int = 0,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line,
                      tag: Any? = nil,
                      asynchronous async: Bool = asyncLoggingEnabled,
                      ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(), level: level, flag: .info, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

@inlinable
public func DDLogWarn(_ message: @autoclosure () -> String,
                      level: DDLogLevel = DDDefaultLogLevel,
                      context: Int = 0,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line,
                      tag: Any? = nil,
                      asynchronous async: Bool = asyncLoggingEnabled,
                      ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(), level: level, flag: .warning, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

@inlinable
public func DDLogVerbose(_ message: @autoclosure () -> String,
                         level: DDLogLevel = DDDefaultLogLevel,
                         context: Int = 0,
                         file: StaticString = #file,
                         function: StaticString = #function,
                         line: UInt = #line,
                         tag: Any? = nil,
                         asynchronous async: Bool = asyncLoggingEnabled,
                         ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(), level: level, flag: .verbose, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

@inlinable
public func DDLogError(_ message: @autoclosure () -> String,
                       level: DDLogLevel = DDDefaultLogLevel,
                       context: Int = 0,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line,
                       tag: Any? = nil,
                       asynchronous async: Bool = false,
                       ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(), level: level, flag: .error, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

/// Returns a String of the current filename, without full path or extension.
///
/// Analogous to the C preprocessor macro `THIS_FILE`.
public func currentFileName(_ fileName: StaticString = #file) -> String {
    var str = String(describing: fileName)
    if let idx = str.range(of: "/", options: .backwards)?.upperBound {
        str = String(str[idx...])
    }
    if let idx = str.range(of: ".", options: .backwards)?.lowerBound {
        str = String(str[..<idx])
    }
    return str
}

// swiftlint:disable identifier_name
// swiftlint doesn't like func names that begin with a capital letter - deprecated
@available(*, deprecated, message: "Please use currentFileName", renamed: "currentFileName")
public func CurrentFileName(_ fileName: StaticString = #file) -> String {
    return currentFileName(fileName)
}
