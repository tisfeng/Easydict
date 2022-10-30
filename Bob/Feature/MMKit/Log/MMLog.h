//
//  MMLog.h
//  Bob
//
//  Created by ripper on 2019/6/14.
//  Copyright © 2019 ripperhe. All rights reserved.
//

/**
 Podfile 设置 use_frameworks! 之后，LOG_ASYNC_ENABLED 宏定义设置无效了，具体看
 https://github.com/CocoaLumberjack/CocoaLumberjack/issues/833
 故直接利用 LOG_MAYBE 定义 Log
 
 默认设置：
 * DEBUG 模式：
 *      输出 MMLogVerbose & MMLogInfo
 *      同步打印
 * 非 DEBUG 模式:
 *      仅输出 MMLogInfo
 *      异步打印

 自定义设置：
 * MMDefaultLogLevel: DDLogLevelOff => 全部不输出；DDLogLevelInfo => 仅输出 MMLogInfo；DDLogLevelAll => 全部输出
 * MMDefaultLogAsyncEnabled: NO => 同步打印；YES => 异步输出
 */

#import <CocoaLumberjack/CocoaLumberjack.h>

@interface MMManagerForLog : NSObject

/** 默认的DDLog对象，日志存储于Default文件夹 */
+ (DDLog *)sharedDDLog;

/** 根据名字创建一个独立的DDLog，用于日志文件输出分离 */
+ (DDLog *)createADDLogWithName:(NSString *)name;

/** 日志系统根文件夹 */
+ (NSString *)rootLogDirectory;

/** 默认日志文件夹 */
+ (NSString *)defaultLogDirectory;

/** 根据名字获取对应DDLog的日志文件夹 */
+ (NSString *)logDirectoryWithName:(NSString *)name;

@end


extern DDLogLevel MMDefaultLogLevel;
extern BOOL MMDefaultLogAsyncEnabled;


#define MMLogInfo(frmt, ...)    LOG_MAYBE_TO_DDLOG([MMManagerForLog sharedDDLog], MMDefaultLogAsyncEnabled, MMDefaultLogLevel, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define MMLogVerbose(frmt, ...) LOG_MAYBE_TO_DDLOG([MMManagerForLog sharedDDLog], MMDefaultLogAsyncEnabled, MMDefaultLogLevel, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define MMDDLogInfo(ddlog, frmt, ...)    LOG_MAYBE_TO_DDLOG(ddlog, MMDefaultLogAsyncEnabled, MMDefaultLogLevel, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define MMDDLogVerbose(ddlog, frmt, ...) LOG_MAYBE_TO_DDLOG(ddlog, MMDefaultLogAsyncEnabled, MMDefaultLogLevel, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)


#define MMAssert(condition, desc, ...)    \
    do {                \
        if(!(condition)) {  \
            LOG_MAYBE_TO_DDLOG([MMManagerForLog sharedDDLog], NO, DDLogLevelAll, DDLogFlagError, 0, nil, __PRETTY_FUNCTION__, desc, ##__VA_ARGS__);  \
        }   \
        NSAssert(condition, desc, ##__VA_ARGS__);   \
    } while(0)

#define MMCAssert(condition, desc, ...)    \
    do {                \
        if(!(condition)) {  \
            LOG_MAYBE_TO_DDLOG([MMManagerForLog sharedDDLog], NO, DDLogLevelAll, DDLogFlagError, 0, nil, __PRETTY_FUNCTION__, desc, ##__VA_ARGS__);  \
        }   \
        NSCAssert(condition, desc, ##__VA_ARGS__);   \
    } while(0)

#define MMDDAssert(ddlog, condition, desc, ...)    \
    do {                \
        if(!(condition)) {  \
            LOG_MAYBE_TO_DDLOG(ddlog, NO, DDLogLevelAll, DDLogFlagError, 0, nil, __PRETTY_FUNCTION__, desc, ##__VA_ARGS__);  \
        }   \
        NSAssert(condition, desc, ##__VA_ARGS__);   \
    } while(0)

#define MMDDCAssert(ddlog, condition, desc, ...)    \
    do {                \
        if(!(condition)) {  \
            LOG_MAYBE_TO_DDLOG(ddlog, NO, DDLogLevelAll, DDLogFlagError, 0, nil, __PRETTY_FUNCTION__, desc, ##__VA_ARGS__);  \
        }   \
        NSCAssert(condition, desc, ##__VA_ARGS__);   \
    } while(0)
