//
//  NSMutableAttributedString+MM.m
//  Bob
//
//  Created by ripper on 2019/11/12.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSMutableAttributedString+MM.h"
#import "NSAttributedString+MM.h"

@implementation NSMutableAttributedString (MM)

+ (NSMutableAttributedString *)mm_mutableAttributedStringWithString:(NSString *)text font:(NSFont *)font color:(NSColor *)color {
    NSAttributedString *attStr = [self mm_attributedStringWithString:text font:font color:color];
    NSMutableAttributedString *mutableAttStr = [[NSMutableAttributedString alloc] initWithAttributedString:attStr];
    return mutableAttStr;
}

- (void)mm_updateWithFont:(NSFont *)font color:(NSColor *)color {
    [self mm_updateWithFont:font color:color range:NSMakeRange(0, self.length)];
}

- (void)mm_updateWithFont:(NSFont *)font color:(NSColor *)color range:(NSRange)range {
    if (font) {
        [self addAttribute:NSFontAttributeName value:font range:range];
    }
    if (color) {
        [self addAttribute:NSForegroundColorAttributeName value:color range:range];
    }
}

- (void)mm_updateWithFont:(NSFont *)font color:(NSColor *)color pattern:(NSString *)pattern {
    NSError *error = nil;
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"mm_updateWithFont:color:pattern: 正则匹配错误\nerror:%@", error);
    }
    NSArray *matchResults = [regular matchesInString:self.string options:0 range:NSMakeRange(0, self.length)];
    for (NSTextCheckingResult *match in matchResults) {
        [self mm_updateWithFont:font color:color range:match.range];
    }
}

@end
