//
//  NSString+EZSplit.m
//  Easydict
//
//  Created by tisfeng on 2023/10/11.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZSplit.h"

@implementation NSString (EZSplit)

/**
 Split camel case text.
 
 anchoredDraggableState --> anchored Draggable State
 AnchoredDraggableState --> Anchored Draggable State
 GetHTTP --> Get HTTP
 GetHTTPCode --> Get HTTP Code
 DECLINED BY VENDOR
 */
- (NSString *)splitCamelCaseText {
    NSMutableString *outputText = [NSMutableString string];

    for (int i = 0; i < self.length; i++) {
        NSString *currentChar = [self substringWithRange:NSMakeRange(i, 1)];
        if ([self isUppercaseChar:currentChar]) {
            if (i > 0) {
                NSString *prevChar = [self substringWithRange:NSMakeRange(i - 1, 1)];
                if ([self isLowercaseChar:prevChar]) {
                    [outputText appendString:@" "];
                } else {
                    if (i < self.length - 1) {
                        NSString *nextChar = [self substringWithRange:NSMakeRange(i + 1, 1)];
                        if ([self isLowercaseChar:nextChar]) {
                            [outputText appendString:@" "];
                        }
                    }
                }
            }
        }
        [outputText appendString:currentChar];
    }

    return outputText;
}

- (BOOL)isUppercaseChar:(NSString *)charString {
    NSCharacterSet *uppercaseCharSet = [NSCharacterSet uppercaseLetterCharacterSet];
    return [uppercaseCharSet characterIsMember:[charString characterAtIndex:0]];
}

- (BOOL)isLowercaseChar:(NSString *)charString {
    NSCharacterSet *lowercaseCharSet = [NSCharacterSet lowercaseLetterCharacterSet];
    return [lowercaseCharSet characterIsMember:[charString characterAtIndex:0]];
}

/**
 Split snake case text.
 
 anchored_draggable_state --> anchored draggable state
 */
- (NSString *)splitSnakeCaseText {
    NSMutableString *outputText = [NSMutableString string];

    NSArray *components = [self componentsSeparatedByString:@"_"];
    outputText = [[components componentsJoinedByString:@" "] mutableCopy];

    return outputText;
}

@end
