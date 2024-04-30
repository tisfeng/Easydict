//
//  MMConsoleLogFormatter.m
//  ExampleDevelop
//
//  Created by ripper on 2019/6/19.
//  Copyright © 2019 picooc. All rights reserved.
//

#import "MMConsoleLogFormatter.h"

@implementation MMConsoleLogFormatter

#pragma mark - DDLogFormatter protocol

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    return [NSString stringWithFormat:@"[%@ ● %zd ● %@] %@ ● %@", logMessage.fileName, logMessage.line, [self logMessageEmoji:logMessage], logMessage.function, logMessage->_message];
}

#pragma mark - Public

- (NSString *)logMessageEmoji:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage->_flag) {
        case DDLogFlagError:
            logLevel = @"❌";
            break;
        case DDLogFlagWarning:
            logLevel = @"⚠️";
            break;
        case DDLogFlagInfo:
            logLevel = @"ℹ️";
            break;
        case DDLogFlagDebug:
            logLevel = @"🔨";
            break;
        default:
            logLevel = @"⚙️";
            break;
    }
    return logLevel;
}

@end
