//
//  NSArray+EZChineseText.m
//  Easydict
//
//  Created by tisfeng on 2023/5/4.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSArray+EZChineseText.h"
#import "NSString+EZChineseText.h"

@implementation NSArray (EZChineseText)

/// Convert translated results to Traditional Chinese manually.  开门 --> 開門
- (NSArray<NSString *> *)toTraditionalChineseTexts {
    NSMutableArray *traditionalTexts = [NSMutableArray array];
    for (NSString *text in self) {
        NSString *newText = [text toTraditionalChineseText];
        [traditionalTexts addObject:newText];
    }
    return traditionalTexts;
}

/// Convert translated results to Simplified Chinese manually.  開門 --> 开门
- (NSArray<NSString *> *)toSimplifiedChineseTexts {
    NSMutableArray *simplifiedTexts = [NSMutableArray array];
    for (NSString *text in self) {
        NSString *newText = [text toSimplifiedChineseText];
        [simplifiedTexts addObject:newText];
    }
    return simplifiedTexts;
}

- (NSArray<NSString *> *)removeExtraLineBreaks {
    NSMutableArray *texts = [NSMutableArray array];
    for (NSString *text in self) {
        NSString *newText = [text removeExtraLineBreaks];
        [texts addObject:newText];
    }
    return texts;
}

@end
