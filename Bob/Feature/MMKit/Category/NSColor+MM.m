//
//  NSColor+MM.m
//  Bob
//
//  Created by ripper on 2019/11/12.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSColor+MM.h"

@implementation NSColor (MM)

+ (NSColor *)mm_randomColor {
    // rgb 值均为 1，则为白色，让所有值为 0.6以上，则颜色较浅
    int start = 60;
    int length = 40;
    CGFloat r = (CGFloat)(1 + start + arc4random() % length) / 100 ;
    CGFloat g = (CGFloat)(1 + start + arc4random() % length) / 100 ;
    CGFloat b = (CGFloat)(1 + start + arc4random() % length) / 100 ;
    return [self colorWithRed:r green:g blue:b alpha:1];
}

+ (NSColor *)mm_colorWithHexString:(NSString *)hexStr {
    return [self mm_colorWithHexString:hexStr alpha:1];
}

+ (NSColor *)mm_colorWithHexString:(NSString *)hexStr alpha:(CGFloat)alpha {
    if (!hexStr.length) {
        NSAssert(0, @"mm_colorWithHexString: 颜色字符串不能为空");
        return [self whiteColor];
    }

    NSString *hexRegex = @"^#[0-9a-fA-F]{6}$";
    NSPredicate *hexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", hexRegex];
    if (![hexPredicate evaluateWithObject:hexStr]) {
        NSAssert(0, @"mm_colorWithHexString: 颜色格式不对");
        return [self whiteColor];
    }else {
        unsigned red,green,blue;
        NSRange range;
        range.length = 2;
        range.location = 1;
        [[NSScanner scannerWithString:[hexStr substringWithRange:range]] scanHexInt:&red];
        range.location = 3;
        [[NSScanner scannerWithString:[hexStr substringWithRange:range]] scanHexInt:&green];
        range.location = 5;
        [[NSScanner scannerWithString:[hexStr substringWithRange:range]] scanHexInt:&blue];
        NSColor *color= [self colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha];
        return color;
    }
}

+ (NSColor *)mm_colorWithIntR:(int)r g:(int)g b:(int)b {
    return [self colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

+ (NSColor *)mm_colorWithIntR:(int)r g:(int)g b:(int)b alhpa:(CGFloat)alpha {
    return [self colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:alpha];
}

@end
