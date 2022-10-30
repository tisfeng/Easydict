//
//  MMFileLogFormatter.m.m
//  Bob
//
//  Created by ripper on 2019/6/14.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "MMFileLogFormatter.h"

/**
 Reference:
 * https://github.com/CocoaLumberjack/CocoaLumberjack/blob/master/Documentation/CustomFormatters.md
 */

@interface MMFileLogFormatter() {
    DDAtomicCounter *atomicLoggerCounter;
    NSDateFormatter *threadUnsafeDateFormatter;
}

@end

@implementation MMFileLogFormatter

- (NSString *)stringFromDate:(NSDate *)date {
    int32_t loggerCount = [atomicLoggerCounter value];
    
    if (loggerCount <= 1) {
        // Single-threaded mode.
        
        if (threadUnsafeDateFormatter == nil) {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        }
        
        return [threadUnsafeDateFormatter stringFromDate:date];
    } else {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"MMFileLogFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage->_flag) {
        case DDLogFlagError    : logLevel = @"❌"; break;
        case DDLogFlagWarning  : logLevel = @"W"; break;
        case DDLogFlagInfo     : logLevel = @"I"; break;
        case DDLogFlagDebug    : logLevel = @"D"; break;
        default                : logLevel = @"V"; break;
    }
    return [NSString stringWithFormat:@"[%@ ● %@ ● %zd ● %@] %@ ● %@", [self stringFromDate:logMessage.timestamp], logMessage.fileName, logMessage.line, logLevel, logMessage.function, logMessage->_message];
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    [atomicLoggerCounter increment];
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    [atomicLoggerCounter decrement];
}

@end
