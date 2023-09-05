//
//  NSString+EZRegex.m
//  Easydict
//
//  Created by tisfeng on 2023/9/5.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZRegex.h"

@implementation NSString (EZRegex)

/// Get string value from HTML string with pattern.
- (nullable NSString *)getStringValueWithPattern:(NSString *)pattern {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    if (match.numberOfRanges >= 2) {
        NSRange range = [match rangeAtIndex:1];
        NSString *value = [self substringWithRange:range];
        return value;
    }
    return nil;
}

@end
