//
//  MMCrashFileTool.m
//  MMKit
//
//  Created by wenquan on 2018/11/22.
//

#import "MMCrashFileTool.h"
#import "MMLog.h"


@implementation MMCrashFileTool

+ (void)saveCrashLog:(NSString *)log fileName:(NSString *)fileName {
    if ([log isKindOfClass:[NSString class]] && (log.length > 0)) {
        // 获取当前年月日字符串
        NSDateFormatter *dateFormart = [[NSDateFormatter alloc] init];
        [dateFormart setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        dateFormart.timeZone = [NSTimeZone systemTimeZone];
        NSString *dateString = [dateFormart stringFromDate:[NSDate date]];

        NSFileManager *manager = [NSFileManager defaultManager];
        NSString *crashDirectory = [self crashDirectory];
        if (crashDirectory && [manager fileExistsAtPath:crashDirectory]) {
            // 获取crash保存的路径
            NSString *crashPath = [crashDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Crash %@.log", dateString]];
            if ([fileName isKindOfClass:[NSString class]] && (fileName.length > 0)) {
                crashPath = [crashDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %@.log", fileName, dateString]];
            }

            [log writeToFile:crashPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}

+ (NSString *)crashDirectory {
    // Keep crash reports under the app log root so they are included when exporting logs.
    NSString *directory = [MMManagerForLog logDirectoryWithName:@"Crash"];

    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:directory]) {
        [manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return directory;
}

@end
