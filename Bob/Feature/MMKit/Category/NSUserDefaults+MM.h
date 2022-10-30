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

+ (id _Nullable)mm_read:(NSString *)key;
+ (id _Nullable)mm_read:(NSString *)key defaultValue:(id _Nullable)defaultValue checkClass:(Class)cls;

+ (void)mm_write:(id _Nullable)obj forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
