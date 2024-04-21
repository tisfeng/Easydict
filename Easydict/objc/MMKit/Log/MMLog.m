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
#import "EZDeviceSystemInfo.h"

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
        [DDOSLogger sharedInstance].logFormatter = consoleFormatter;
    });
}

+ (void)configDDLog:(DDLog *)ddlog name:(NSString *)name {
    // https://github.com/CocoaLumberjack/CocoaLumberjack/blob/master/Documentation/GettingStarted.md
    NSCAssert(name.length, @"MMLog: 日志 name 不能为空");

    // terminal, use os_log
    [ddlog addLogger:[DDOSLogger sharedInstance]];

    // 文件输出
    MMFileLogFormatter *fileFormatter = [MMFileLogFormatter new];
    DDLogFileManagerDefault *fileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:[self logDirectoryWithName:name]];
    fileManager.maximumNumberOfLogFiles = 10;
    fileManager.logFilesDiskQuota = 20 * 1024 * 1024;
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:fileManager];
    
    fileLogger.logFormatter = fileFormatter;
    // file log
    [ddlog addLogger:fileLogger withLevel:MMDefaultLogLevel];
}

+ (DDLog *)sharedDDLog {
    static DDLog *_sharedLog = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLog = [self createADDLogWithName:kDefaultLogName];
    });
    return _sharedLog;
}

+ (DDLog *)createADDLogWithName:(NSString *)name {
    NSAssert(name.length, @"MMLog: DDLog名字不能为空");
    if (!name.length) {
        return nil;
    }
    
    DDLog *log = [[DDLog alloc] init];
    [self configDDLog:log name:name];
    NSString *identifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    
    NSDictionary *deviceSystemInfo = [EZDeviceSystemInfo getDeviceSystemInfo];

    MMDDLogInfo(log, @"\n=========>\n🚀 %@ 启动 MMLog(%@)...\n%@\n日志文件夹:\n%@\n<=========\n", identifier, name, deviceSystemInfo, [self logDirectoryWithName:name]);
    
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
