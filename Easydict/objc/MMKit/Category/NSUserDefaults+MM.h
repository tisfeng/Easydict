//
//  NSUserDefaults+MM.h
//  Bob
//
//  Created by ripper on 2019/11/14.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSUserDefaults (MM)

/// Read string from user defaults, if not exist, return defaultValue and write it to user defaults.
+ (NSString *)mm_readString:(NSString *)key defaultValue:(NSString *)defaultValue;

/// Read integer from user defaults, if not exist, return defaultValue and write it to user defaults.
+ (NSInteger)mm_readInteger:(NSString *)key defaultValue:(NSInteger)defaultValue;

/// Read bool from user defaults, if not exist, return defaultValue and write it to user defaults.
+ (BOOL)mm_readBool:(NSString *)key defaultValue:(BOOL)defaultValue;

+ (id _Nullable)mm_read:(NSString *)key;
+ (id _Nullable)mm_read:(NSString *)key defaultValue:(id _Nullable)defaultValue checkClass:(Class)cls;

+ (void)mm_write:(id _Nullable)obj forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
