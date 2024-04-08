//
//  NSAttributedString+MM.m
//  Bob
//
//  Created by ripper on 2019/11/12.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSAttributedString+MM.h"

@implementation NSAttributedString (MM)

+ (NSAttributedString *)mm_attributedStringWithString:(NSString *)text font:(NSFont *)font {
    if (!text.length || !font) {
        NSAssert(0, @"mm_attributedStringWithString: 参数不对");
        return nil;
    }

    NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:text
                                                                 attributes:@{
                                                                     NSFontAttributeName : font,
                                                                 }];
    return attStr;
}

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
    return [self mm_getTextSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width;
}

// Get attribute string height.
- (CGFloat)mm_getTextHeightWithWidth:(CGFloat)width {
    return [self mm_getTextSize:CGSizeMake(width, CGFLOAT_MAX)].height;
}

- (CGSize)mm_getTextSize:(CGSize)designatedSize {
    if (!designatedSize.width || !designatedSize.height) {
        return CGSizeZero;
    }

    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:designatedSize];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [layoutManager glyphRangeForTextContainer:textContainer];
    CGSize size = [layoutManager usedRectForTextContainer:textContainer].size;
    return size;
}

- (CGSize)mm_getTextSize {
    return [self mm_getTextSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
}

@end
