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
                                                                              NSFontAttributeName:font,
                                                                              NSForegroundColorAttributeName:color,
                                                                              }];
    return attStr;
}

@end
