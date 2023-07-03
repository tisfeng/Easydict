//
//  NSString+EZCharacterSet.m
//  Easydict
//
//  Created by tisfeng on 2023/6/2.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZCharacterSet.h"
#import "EZTextWordUtils.h"

static NSArray *const kEndPunctuationMarks = @[ @"。", @"？", @"！", @"?", @".", @"!", @";", @":", @"：", @"...", @"……" ];

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

/// Get first word of string
- (NSString *)firstWord {
    NSArray *words = [self componentsSeparatedByString:@" "];
    NSString *firstWord = [words firstObject];
    return firstWord;
}

/// Get last word of string
- (NSString *)lastWord {
    NSArray *words = [self componentsSeparatedByString:@" "];
    NSString *lastWord = [words lastObject];
    return lastWord;
}

/// Check if text is a end punctuation mark.
- (BOOL)hasEndPunctuationSuffix {
    if (self.length == 0) {
        return NO;
    }
    return [kEndPunctuationMarks containsObject:self.lastChar];
}

- (nullable NSString *)firstChar {
    if (self.length == 0) {
        return nil;
    }
    
    return [self substringToIndex:1];
}

- (nullable NSString *)lastChar {
    if (self.length == 0) {
        return nil;
    }
    
    return [self substringFromIndex:self.length - 1];
}

/// Check if the first word of text is a element of EZPointCharacterList.
- (BOOL)isPointFirstWord {
    NSString *firstWord = [self firstWord];
    return [EZPointCharacterList containsObject:firstWord];
}

- (BOOL)isDashFirstWord {
    NSString *firstWord = [self firstWord];
    return [EZDashCharacterList containsObject:firstWord];
}

- (BOOL)isNumberFirstWord {
    NSString *firstWord = [self firstWord];
    
    NSString *dot = @".";
    if ([firstWord containsString:dot]) {
        NSString *number = [firstWord componentsSeparatedByString:dot].firstObject;
        if (number) {
            return [EZTextWordUtils isNumbers:number];
        }
    }
    return NO;
}

- (BOOL)isListTypeFirstWord {
    BOOL isList = [self isPointFirstWord] || [self isDashFirstWord] || [self isNumberFirstWord];
    return isList;
}

@end
