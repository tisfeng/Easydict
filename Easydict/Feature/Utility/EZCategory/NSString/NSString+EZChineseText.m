//
//  NSString+EZChineseText.m
//  Easydict
//
//  Created by tisfeng on 2023/5/4.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZChineseText.h"
#import "EZTextWordUtils.h"

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

/// Is simplified Chinese.
/// !!!: Characters in the text must be all simplified Chinese word, otherwise it will return NO.
- (BOOL)isSimplifiedChinese {
    /**
     We need to remove symbol characters, otherwise the result will be incorrect.
     
     「真个别离难，不似相逢好」--> “真个别离难，不似相逢好”
     */
    NSString *pureText = [EZTextWordUtils removeNonNormalCharacters:self];
    NSString *simplifiedChinese = [pureText toSimplifiedChineseText];
    if ([simplifiedChinese isEqualToString:pureText]) {
        return YES;
    }
    return NO;
}

@end
