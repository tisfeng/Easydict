//
//  EZConstKey.h
//  Easydict
//
//  Created by tisfeng on 2023/6/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZEnumTypes.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZDictionaryKey = @"Dictionary";
static NSString *const EZDisabledAppBundleIDListKey = @"EZDisabledAppBundleIDListKey";

@interface EZConstKey : NSObject

+ (NSString *)constkey:(NSString *)key windowType:(EZWindowType)windowType;

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType;

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType windowType:(EZWindowType)windowType;

@end

NS_ASSUME_NONNULL_END
