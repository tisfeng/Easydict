//
//  NSArray+EZChineseText.h
//  Easydict
//
//  Created by tisfeng on 2023/5/4.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (EZChineseText)

/// Convert translated results to Traditional Chinese manually.  开门 --> 開門
- (NSArray<NSString *> *)toTraditionalChineseTexts;

/// Convert translated results to Simplified Chinese manually.  開門 --> 开门
- (NSArray<NSString *> *)toSimplifiedChineseTexts;

- (NSArray<NSString *> *)removeExtraLineBreaks;

@end

NS_ASSUME_NONNULL_END
