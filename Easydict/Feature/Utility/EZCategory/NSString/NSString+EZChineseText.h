//
//  NSString+EZChineseText.h
//  Easydict
//
//  Created by tisfeng on 2023/5/4.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EZChineseText)

/// Convert Simplified Chinese to Traditional Chinese.  开门 --> 開門
- (NSString *)toTraditionalChineseText;

/// Convert Traditional Chinese to Simplified Chinese.  開門 --> 开门
- (NSString *)toSimplifiedChineseText;


/// Is simplified Chinese.
/// !!!: Characters in the text must be all simplified Chinese, otherwise it will return NO.
- (BOOL)isSimplifiedChinese;

@end

NS_ASSUME_NONNULL_END
