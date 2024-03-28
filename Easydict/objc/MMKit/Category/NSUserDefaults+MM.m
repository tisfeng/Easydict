//
//  NSUserDefaults+MM.m
//  Bob
//
//  Created by ripper on 2019/11/14.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSUserDefaults+MM.h"

@implementation NSUserDefaults (MM)

/// Read string from user defaults, if not exist, return defaultValue and write it to user defaults.
+ (NSString *)mm_readString:(NSString *)key defaultValue:(NSString *)defaultValue {
    return [NSUserDefaults mm_read:key defaultValue:defaultValue checkClass:NSString.class];
}

/// Read integer from user defaults, if not exist, return defaultValue and write it to user defaults.
+ (NSInteger)mm_readInteger:(NSString *)key defaultValue:(NSInteger)defaultValue {
    return [[NSUserDefaults mm_read:key defaultValue:@(defaultValue) checkClass:NSNumber.class] integerValue];
}

/// Read bool from user defaults, if not exist, return defaultValue and write it to user defaults.
+ (BOOL)mm_readBool:(NSString *)key defaultValue:(BOOL)defaultValue {
    return [[NSUserDefaults mm_read:key defaultValue:@(defaultValue) checkClass:NSNumber.class] boolValue];
}

+ (id)mm_read:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

+ (id)mm_read:(NSString *)key defaultValue:(id)defaultValue checkClass:(Class)cls {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (!value || ![value isKindOfClass:cls]) {
        value = defaultValue;
        [NSUserDefaults mm_write:value forKey:key];
    }
    return value;
}

+ (void)mm_write:(id)obj forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
}

@end
