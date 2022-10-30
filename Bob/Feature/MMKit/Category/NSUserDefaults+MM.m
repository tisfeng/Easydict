//
//  NSUserDefaults+MM.m
//  Bob
//
//  Created by ripper on 2019/11/14.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSUserDefaults+MM.h"

@implementation NSUserDefaults (MM)

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
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
