//
//  NSString+EZHandleInputText.m
//  Easydict
//
//  Created by tisfeng on 2023/10/12.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZHandleInputText.h"
#import "NSString+EZUtils.h"
#import "NSString+EZSplit.h"

static NSString *const kCommentSymbolPrefixPattern = @"^\\s*(//|#)";

@implementation NSString (EZHandleInputText)

/// Split code text by snake case and camel case.
- (NSString *)splitCodeText {
    NSString *queryText = [self splitSnakeCaseText];
    queryText = [queryText splitCamelCaseText];
    
    // Filter empty text
    NSArray *texts = [queryText componentsSeparatedByString:@" "];
    NSMutableArray *newTexts = [NSMutableArray array];
    for (NSString *text in texts) {
        if (text.length) {
            [newTexts addObject:text];
        }
    }
    
    queryText = [newTexts componentsJoinedByString:@" "];
    
    return queryText;
}

/**
 * Creates a {@code UUID} from the string standard representation as
 * described in the {@link #toString} method.
 *
 * @param  name
 *         A string that specifies a {@code UUID}
 *
 * @return  A {@code UUID} with the specified value
 *
 * @throws  IllegalArgumentException
 *          If name does not conform to the string representation as
 *          described in {@link #toString}
 *
 */

/// Remove comment block symbols, /* */
- (NSString *)removeCommentBlockSymbols {
    NSMutableString *mutableSelf = [self mutableCopy];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/\\*+(.*?)\\*+/" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray *results = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    for (NSTextCheckingResult *result in [[results reverseObjectEnumerator] allObjects]) {
        NSRange range = [result rangeAtIndex:1];
        NSString *content = [self substringWithRange:range].trim;
        NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSMutableArray *mutableLines = [NSMutableArray array];
        for (NSString *line in lines) {
            NSString *trimmedLine = [line trim];
            // Remove all prefix *
            NSString *newText = [trimmedLine stringByReplacingOccurrencesOfString:@"\\*+"
                                                                       withString:@""
                                                                          options:NSRegularExpressionSearch
                                                                            range:NSMakeRange(0, trimmedLine.length)];
            [mutableLines addObject:newText.trim];
        }
        
        NSString *modifiedBlock = [mutableLines componentsJoinedByString:@"\n"];
        [mutableSelf replaceCharactersInRange:result.range withString:modifiedBlock];
    }
    
    return mutableSelf;
}

/**
 Remove comment symbols, # and //
 */
- (NSString *)removeCommentSymbols {
    // match // and  #
    NSString *pattern = @"//|#";
    NSString *cleanedText = [self stringByReplacingOccurrencesOfString:pattern
                                                            withString:@""
                                                               options:NSRegularExpressionSearch
                                                                 range:NSMakeRange(0, self.length)];
    return cleanedText;
}


/**
 // These values will persist after the process is killed by the system
 // and remain available via the same object.
 
 hi
 
 // good girl.
 // good boy.
 
 hello
 */

/// Remove adjacent comment symbol prefix, // and #, and try to join texts.
- (NSString *)removeCommentSymbolPrefixAndJoinTexts {
    NSArray *lines = [self componentsSeparatedByString:@"\n"];
    
    NSMutableString *resultText = [NSMutableString string];
    BOOL previousLineIsComment = NO;
    
    for (int i = 0; i < lines.count; i++) {
        NSString *line = lines[i];
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([trimmedLine hasCommentSymbolPrefix]) {
            // 当前行为注释
            trimmedLine = [trimmedLine removeCommentSymbolPrefix].trim;
            
            if (i > 0) {
                NSString *prevLine = lines[i - 1];
                if (previousLineIsComment && ![prevLine hasEndPunctuationSuffix]) {
                    // 如果前一行是注释，拼接当前行
                    [resultText appendString:@" "];
                } else {
                    [resultText appendString:@"\n"];
                }
            }
            
            previousLineIsComment = YES;
            
        } else {
            [resultText appendString:@"\n"];
            previousLineIsComment = NO;
        }
        
        [resultText appendString:trimmedLine];
    }
    
    return resultText;
}

// Remove comment symbol prefix, // and #
- (NSString *)removeCommentSymbolPrefix {
    NSString *cleanedText = [self stringByReplacingOccurrencesOfString:kCommentSymbolPrefixPattern
                                                            withString:@""
                                                               options:NSRegularExpressionSearch
                                                                 range:NSMakeRange(0, self.length)];
    return cleanedText;
}

// Is start with comment symbol prefix, // and #
- (BOOL)hasCommentSymbolPrefix {
    NSRange range = [self rangeOfString:kCommentSymbolPrefixPattern options:NSRegularExpressionSearch];
    return range.location != NSNotFound;
}

/// Filter Private Use Area characters
- (NSString *)filterPrivateUseCharacters {
    /**
     FIX: https://github.com/tisfeng/Easydict/issues/184
     
     But why?
     
     TODO: Fix this bug in a better way.
     */
    
    // Private Use Area (0xE000, 0xF8FF), Ref: https://zh.wikipedia.org/wiki/Unicode%E5%AD%97%E7%AC%A6%E5%B9%B3%E9%9D%A2%E6%98%A0%E5%B0%84
    static const unichar privateUseRangeStart = 0xE000;
    static const unichar privateUseRangeEnd = 0xF8FF;
    
    NSMutableString *filteredText = [NSMutableString string];
    
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        unichar codePoint = [substring characterAtIndex:0];
        // Filter Private Use Area characters
        if (codePoint < privateUseRangeStart || codePoint > privateUseRangeEnd) {
            [filteredText appendString:substring];
        }
    }];
    
    return filteredText;
}

/// Get unicode of text
- (NSString *)unicode {
    // test  \uE684 https://bbs.hupu.com/62547743.html
    NSMutableString *unicodeString = [NSMutableString string];
    for (int i = 0; i < [self length]; i++) {
        [unicodeString appendFormat:@"\\u%04X ", [self characterAtIndex:i]];
    }
    return unicodeString;
}

@end
