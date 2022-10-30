//
//  NSString+MM.m
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSString+MM.h"

@implementation NSString (MM)

// https://stackoverflow.com/questions/8088473/how-do-i-url-encode-a-string
- (NSString *)mm_urlencode {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[self UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

+ (NSString *)mm_stringByCombineComponents:(NSArray<NSString *> *)components separatedString:(NSString *)separatedString {
    if (!components.count) {
        return nil;
    }
    NSMutableString *string = [NSMutableString string];
    [components enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert([obj isKindOfClass:NSString.class], @"参数必须为 NSString");
        [string appendString:obj];
        if (separatedString.length && idx != components.count - 1) {
            [string appendString:separatedString];
        }
    }];
    return string;
}

@end
