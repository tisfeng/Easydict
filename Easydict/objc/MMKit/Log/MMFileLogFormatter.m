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


@interface MMFileLogFormatter () {
    NSDateFormatter *threadUnsafeDateFormatter;
}

@end


@implementation MMFileLogFormatter

#pragma mark - DDLogFormatter protocol

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    return [NSString stringWithFormat:@"[%@ ● %@ ● %zd ● %@] %@ ● %@", [self stringFromDate:logMessage.timestamp], logMessage.fileName, logMessage.line, [self logMessageEmoji:logMessage], logMessage.function, logMessage->_message];
}

#pragma mark -

- (NSString *)stringFromDate:(NSDate *)date {
    // Single-threaded mode.

    if (threadUnsafeDateFormatter == nil) {
        threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
        [threadUnsafeDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }

    return [threadUnsafeDateFormatter stringFromDate:date];
}

@end
