//
//  MMConsoleLogFormatter.m
//  ExampleDevelop
//
//  Created by ripper on 2019/6/19.
//  Copyright © 2019 picooc. All rights reserved.
//

#import "MMConsoleLogFormatter.h"

@implementation MMConsoleLogFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage->_flag) {
        case DDLogFlagError    : logLevel = @"❌"; break;
        case DDLogFlagWarning  : logLevel = @"W"; break;
        case DDLogFlagInfo     : logLevel = @"I"; break;
        case DDLogFlagDebug    : logLevel = @"D"; break;
        default                : logLevel = @"V"; break;
    }
    return [NSString stringWithFormat:@"[%@ ● %zd ● %@] %@ ● %@", logMessage.fileName, logMessage.line, logLevel, logMessage.function, logMessage->_message];
}

@end
