//
//  NSString+EZCharacterSet.m
//  Easydict
//
//  Created by tisfeng on 2023/6/2.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZCharacterSet.h"

@implementation NSString (EZCharacterSet)

/// Check if it is a single letter of the alphabet, like 'a', 'A'
- (BOOL)isAlphabet {
    if (self.length != 1) {
        return NO;
    }
    
    NSString *regex = @"[a-zA-Z]";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:self];
}

- (BOOL)isAlphabeticString {
    NSCharacterSet *letterCharacterSet = [NSCharacterSet letterCharacterSet];
    NSCharacterSet *stringCharacterSet = [NSCharacterSet characterSetWithCharactersInString:self];
    return [letterCharacterSet isSupersetOfSet:stringCharacterSet];
}

/// Check if lowercaseString, like
- (BOOL)isLowercaseString {
    return [self isEqualToString:self.lowercaseString];
}

/// Check if first char is lowercaseString
- (BOOL)isLowercaseFirstChar {
    if (self.length == 0) {
        return NO;
    }
    
    NSString *firstChar = [self substringToIndex:1];
    return [firstChar isLowercaseString];
}

@end
