//
//  NSAttributedString+MM.m
//  Bob
//
//  Created by ripper on 2019/11/12.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSAttributedString+MM.h"


@implementation NSAttributedString (MM)

+ (NSAttributedString *)mm_attributedStringWithString:(NSString *)text font:(NSFont *)font color:(NSColor *)color {
    if (!text.length || !font || !color) {
        NSAssert(0, @"mm_attributedStringWithString: 参数不对");
        return nil;
    }

    NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:text
                                                                 attributes:@{
                                                                     NSFontAttributeName : font,
                                                                     NSForegroundColorAttributeName : color,
                                                                 }];
    return attStr;
}

// Get attribute string width.
- (CGFloat)mm_getTextWidth {
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [layoutManager glyphRangeForTextContainer:textContainer];
    CGSize size = [layoutManager usedRectForTextContainer:textContainer].size;
    return size.width;
}

// Get attribute string height.
- (CGFloat)mm_getTextHeight:(CGFloat)width {
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(width, CGFLOAT_MAX)];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [layoutManager glyphRangeForTextContainer:textContainer];
    CGSize size = [layoutManager usedRectForTextContainer:textContainer].size;
    return size.height;
}

@end
