//
//  NSString+EZCharacterSet.h
//  Easydict
//
//  Created by tisfeng on 2023/6/2.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EZCharacterSet)

/// Check if it is a single letter of the alphabet, like 'a', 'A'
- (BOOL)isAlphabet;

- (BOOL)isAlphabeticString;

/// Check if lowercaseString, like
- (BOOL)isLowercaseString;

/// Check if first char is lowercaseString
- (BOOL)isLowercaseFirstChar;

/// Get first word of string
- (NSString *)firstWord;

/// Get last word of string
- (NSString *)lastWord;

@end

NS_ASSUME_NONNULL_END
