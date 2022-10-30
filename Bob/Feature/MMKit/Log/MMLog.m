//
//  MMLog.m
//  Bob
//
//  Created by ripper on 2019/6/14.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "MMLog.h"
#import "MMConsoleLogFormatter.h"
#import "MMFileLogFormatter.h"

#if DEBUG
DDLogLevel MMDefaultLogLevel = DDLogLevelAll;
BOOL MMDefaultLogAsyncEnabled = NO;
#else
DDLogLevel MMDefaultLogLevel = DDLogLevelInfo;
BOOL MMDefaultLogAsyncEnabled = YES;
#endif

#define kDefaultLogName @"Default"

@implementation MMManagerForLog

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 系统日志、控制台 格式设置
        MMConsoleLogFormatter *consoleFormatter = [MMConsoleLogFormatter new];
        if (@available(macOS 10.12, *)) {
            [DDOSLogger sharedInstance].logFormatter = consoleFormatter;
        }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [DDASLLogger sharedInstance].logFormatter = consoleFormatter;
#pragma clang diagnostic pop
        }
    });
}

+ (void)configDDLog:(DDLog *)ddlog name:(NSString *)name {
    // https://github.com/CocoaLumberjack/CocoaLumberjack/blob/master/Documentation/GettingStarted.md
    NSCAssert(name.length, @"MMLog: 日志 name 不能为空");
    
    // 系统日志、控制台
    if (@available(iOS 10.0, *)) {
        [ddlog addLogger:[DDOSLogger sharedInstance]];
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [ddlog addLogger:[DDASLLogger sharedInstance]];
#pragma clang diagnostic pop
    }
    
    // 文件输出
    MMFileLogFormatter *fileFormatter = [MMFileLogFormatter new];
    DDLogFileManagerDefault *fileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:[self logDirectoryWithName:name]];
    fileManager.maximumNumberOfLogFiles = 200;
    fileManager.logFilesDiskQuota = 20 * 1024 * 1024;
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:fileManager];
    fileLogger.logFormatter = fileFormatter;
    [ddlog addLogger:fileLogger];
}

+ (DDLog *)sharedDDLog {
    static DDLog *_sharedLog = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLog = [[DDLog alloc] init];
        [self configDDLog:_sharedLog name:kDefaultLogName];
        NSString *identifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        MMDDLogInfo(_sharedLog, @"\n=========>\n🚀 %@(%@)[%@] 启动 MMLog(Defalut)...\n\n日志文件夹:\n%@\n<=========", identifier, version, build, [self defaultLogDirectory]);
    });
    return _sharedLog;
}

+ (DDLog *)createADDLogWithName:(NSString *)name {
    NSAssert(name.length, @"MMLog: DDLog名字不能为空");
    if (!name.length) return nil;
    if ([name isEqualToString:kDefaultLogName]) return [self sharedDDLog];
    DDLog *log = [[DDLog alloc] init];
    [self configDDLog:log name:name];
    NSString *identifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    MMDDLogInfo(log, @"\n=========>\n🚀 %@(%@)[%@] 启动 MMLog(%@)...\n\n日志文件夹:\n%@\n<=========", identifier, version, build, name, [self logDirectoryWithName:name]);
    return log;
}

+ (NSString *)rootLogDirectory {
    static NSString *_path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        // 加上 identifier，兼容关闭沙盒的情况
        NSString *identifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        _path = [cachesDirectory stringByAppendingFormat:@"/%@/MMLogs", identifier];
    });
    return _path;
}

+ (NSString *)defaultLogDirectory {
    static NSString *_path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _path = [self logDirectoryWithName:kDefaultLogName];
    });
    return _path;
}

+ (NSString *)logDirectoryWithName:(NSString *)name {
    NSAssert(name.length, @"MMLog: DDLog名字不能为空");
    if (!name.length) return nil;
    return [[self rootLogDirectory] stringByAppendingPathComponent:name];
}

@end

