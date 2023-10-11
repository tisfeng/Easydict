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
 */
- (NSString *)splitCamelCaseText {
    NSMutableString *outputText = [NSMutableString string];
    NSCharacterSet *uppercaseCharSet = [NSCharacterSet uppercaseLetterCharacterSet];

    for (int i = 0; i < self.length; i++) {
        NSString *currentChar = [self substringWithRange:NSMakeRange(i, 1)];

        if ([uppercaseCharSet characterIsMember:[currentChar characterAtIndex:0]]) {
            if (i > 0) {
                NSString *prevChar = [self substringWithRange:NSMakeRange(i - 1, 1)];

                if (![uppercaseCharSet characterIsMember:[prevChar characterAtIndex:0]]) {
                    [outputText appendString:@" "];
                } else {
                    if (i < self.length - 1) {
                        NSString *nextChar = [self substringWithRange:NSMakeRange(i + 1, 1)];

                        if (![uppercaseCharSet characterIsMember:[nextChar characterAtIndex:0]]) {
                            [outputText appendString:@" "];
                        }
                    }
                }
            }
            [outputText appendString:currentChar];
        } else {
            [outputText appendString:currentChar];
        }
    }

    return outputText;
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
