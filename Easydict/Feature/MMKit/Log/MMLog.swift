//
//  MMLog.swift
//  ExampleDevelop
//
//  Created by ripper on 2019/6/20.
//  Copyright © 2019 picooc. All rights reserved.
//

/**
 ⚠️ 设置 dynamicLogLevel 会影响到日志输出
 */

import CocoaLumberjack

@inlinable
public func MMLogInfo(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line,
                      ddlog: DDLog = MMManagerForLog.sharedDDLog()) {
    DDLogInfo(message(), level: MMDefaultLogLevel, file: file, function: function, line: line, asynchronous: MMDefaultLogAsyncEnabled.boolValue, ddlog: ddlog)
}

@inlinable
public func MMLogVerbose(_ message: @autoclosure () -> String,
                         file: StaticString = #file,
                         function: StaticString = #function,
                         line: UInt = #line,
                         ddlog: DDLog = MMManagerForLog.sharedDDLog()) {
    DDLogVerbose(message(), level: MMDefaultLogLevel, file: file, function: function, line: line, asynchronous: MMDefaultLogAsyncEnabled.boolValue, ddlog: ddlog)
}

@inlinable
public func MMAssert(_ condition: @autoclosure () -> Bool,
                     _ message: @autoclosure () -> String = "",
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line,
                     ddlog: DDLog = MMManagerForLog.sharedDDLog()) {
    if !condition() {
        DDLogError(message(), level: DDLogLevel.all, file: file, function: function, line: line, asynchronous: false, ddlog: ddlog)
        Swift.assertionFailure(message(), file: file, line: line)
    }
}
