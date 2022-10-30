//
//  MMCrash.m
//  Bob
//
//  Created by ripper on 2019/12/10.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "MMCrash.h"
#import "MMCrashUncaughtExceptionHandler.h"
#import "MMCrashSignalExceptionHandler.h"
#import "MMCrashFileTool.h"

@implementation MMCrash

+ (void)registerHandler {
    [MMCrashUncaughtExceptionHandler registerHandler];
    [MMCrashSignalExceptionHandler registerHandler];
}

+ (NSString *)crashDirectory {
    return [MMCrashFileTool crashDirectory];
}

@end
