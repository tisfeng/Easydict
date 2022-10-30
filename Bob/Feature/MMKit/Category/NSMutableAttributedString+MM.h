//
//  NSMutableAttributedString+MM.h
//  Bob
//
//  Created by ripper on 2019/11/12.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableAttributedString (MM)

+ (NSMutableAttributedString *)mm_mutableAttributedStringWithString:(NSString *)text font:(NSFont *)font color:(NSColor *)color;

- (void)mm_updateWithFont:(nullable NSFont *)font color:(nullable NSColor *)color;
- (void)mm_updateWithFont:(nullable NSFont *)font color:(nullable NSColor *)color range:(NSRange)range;
/// 根据正则表达式更新字符串 e.g. pattern - @"[0-9]+" 设置所有数字
- (void)mm_updateWithFont:(nullable NSFont *)font color:(nullable NSColor *)color pattern:(NSString *)pattern;

@end

NS_ASSUME_NONNULL_END
