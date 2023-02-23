//
//  NSString+EZConvenience.h
//  Easydict
//
//  Created by tisfeng on 2023/1/1.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EZConvenience)

- (NSString *)trim;

- (NSString *)trimToMaxLength:(NSUInteger)maxLength;

- (NSString *)encode;

- (void)copyToPasteboard;

- (BOOL)isHttpURL;

- (NSString *)md5;

/// Convert Simplified Chinese to Traditional Chinese.
- (NSString *)toTraditionalChineseText;
/// Convert Traditional Chinese to Simplified Chinese.
- (NSString *)toSimplifiedChineseText;

@end

NS_ASSUME_NONNULL_END
