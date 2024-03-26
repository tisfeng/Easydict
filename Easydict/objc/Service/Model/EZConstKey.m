//
//  EZConstKey.m
//  Easydict
//
//  Created by tisfeng on 2023/6/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZConstKey.h"

@implementation EZConstKey

+ (NSString *)constkey:(NSString *)key windowType:(EZWindowType)windowType {
    return [NSString stringWithFormat:@"%@-window%@", key, @(windowType)];
}

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType {
    return [NSString stringWithFormat:@"%@-%@", serviceType, key];
}

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType windowType:(EZWindowType)windowType {
    NSString *constKey = [self constkey:key serviceType:serviceType];
    constKey = [NSString stringWithFormat:@"%@-window%@", key, @(windowType)];
    return constKey;
}

@end
