//
//  NSAttributedString+MM.h
//  Bob
//
//  Created by ripper on 2019/11/12.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSAttributedString (MM)

// Get attribute string width.
- (CGFloat)mm_getTextWidth;

// Get attribute string height.
- (CGFloat)mm_getTextHeightWithWidth:(CGFloat)width;

- (CGSize)mm_getTextSize:(CGSize)designatedSize;

- (CGSize)mm_getTextSize;

+ (NSAttributedString *)mm_attributedStringWithString:(NSString *)text font:(NSFont *)font;

+ (NSAttributedString *)mm_attributedStringWithString:(NSString *)text font:(NSFont *)font color:(NSColor *)color;

@end

NS_ASSUME_NONNULL_END
