//
//  EZLog.h
//  Easydict
//
//  Created by tisfeng on 2022/12/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZWindowManager.h"
#import "EZQueryService.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZLog : NSObject

+ (void)setupCrashLogService;
+ (void)setCrashEnabled:(BOOL)enabled;
+ (void)logEventWithName:(NSString *)name parameters:(nullable NSDictionary *)dict;

+ (void)logWindowAppear:(EZWindowType)windowType;
+ (void)logQueryService:(EZQueryService *)service;

+ (void)logAppInfo;

+ (NSString *)textLengthRange:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
