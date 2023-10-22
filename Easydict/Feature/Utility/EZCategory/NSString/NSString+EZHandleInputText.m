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
 Remove comment symbols
 */
- (NSString *)removeCommentSymbols {
    // good # girl /*** boy */ --> good  girl  boy
    
    // match /*
    NSString *pattern1 = @"/\\*+";
    
    // match */
    NSString *pattern2 = @"[/*]+";
    
    // match // and  #
    NSString *pattern3 = @"//|#";
    
    NSString *combinedPattern = [NSString stringWithFormat:@"%@|%@|%@", pattern1, pattern2, pattern3];
    
    NSString *cleanedText = [self stringByReplacingOccurrencesOfString:combinedPattern
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
- (NSString *)removeCommentSymbolPrefixAndJoinTexts {
    // 分割文本为行数组
    NSArray *lines = [self componentsSeparatedByString:@"\n"];
    
    NSMutableString *resultText = [NSMutableString string];
    BOOL previousLineIsComment = NO;
    
    for (int i = 0; i < lines.count; i++) {
        NSString *line = lines[i];
        
        // 去除行首和行尾的空格和换行符
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
