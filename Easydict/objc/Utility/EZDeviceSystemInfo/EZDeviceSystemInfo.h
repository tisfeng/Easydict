//
//  EZDeviceSystemInfo.h
//  Easydict
//
//  Created by tisfeng on 2023/7/12.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZDeviceSystemInfo : NSObject

+ (NSDictionary *)getDeviceSystemInfo;

/// Get system version, eg 14.0.0
+ (NSString *)getSystemVersion;

@end

NS_ASSUME_NONNULL_END
