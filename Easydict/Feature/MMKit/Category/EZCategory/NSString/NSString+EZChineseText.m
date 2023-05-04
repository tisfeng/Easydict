//
//  NSString+EZChineseText.m
//  Easydict
//
//  Created by tisfeng on 2023/5/4.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZChineseText.h"

@implementation NSString (EZChineseText)

/// Convert Simplified Chinese to Traditional Chinese.  开门 --> 開門
- (NSString *)toTraditionalChineseText {
    NSString *traditionalChinese = [self stringByApplyingTransform:@"Hans-Hant" reverse:NO];
    return traditionalChinese;
}

/// Convert Traditional Chinese to Simplified Chinese.  開門 --> 开门
- (NSString *)toSimplifiedChineseText {
    NSString *simplifiedChinese = [self stringByApplyingTransform:@"Hant-Hans" reverse:NO];
    return simplifiedChinese;
}

@end
