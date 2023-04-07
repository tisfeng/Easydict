//
//  EZTextWordUtils.h
//  Easydict
//
//  Created by tisfeng on 2023/4/6.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZTextWordUtils : NSObject

+ (BOOL)shouldQueryDictionary:(NSString *)text language:(EZLanguage)langugae;

/// Check if text is a English word. Note: B612 is not a word.
+ (BOOL)isEnglishWord:(NSString *)text;

/// Check if text is a English phrase, like B612, 9527, Since they are detected as English, should query dict, but don't have pos.
+ (BOOL)isEnglishPhrase:(NSString *)text;

/// Use NLTokenizer to check if text is a word.
+ (BOOL)isWord:(NSString *)text;

/// Count word count of text.
+ (NSInteger)wordCount:(NSString *)text;

/// Use NLTagger to check if text is a word.
+ (BOOL)isWord2:(NSString *)text;

/// Use NSSpellChecker to check word spell.
+ (BOOL)isSpelledCorrectly:(NSString *)word ;

/// Check if text is a Chinese word, length <= 4, 倾国倾城
+ (BOOL)isChineseWord:(NSString *)text;

/// Check if text is a Chinese phrase, length <= 5, 今宵别梦寒
+ (BOOL)isChinesePhrase:(NSString *)text;

+ (BOOL)isChineseText:(NSString *)text;
+ (BOOL)isChineseText2:(NSString *)text;

/// Check if text is a sentence, use NLTokenizer.
+ (BOOL)isSentence:(NSString *)text;

/// Sentence count of text.
+ (NSInteger)sentenceCount:(NSString *)text;


#pragma mark - Handle extra quotes.

/// Check if self.queryModel.queryText has prefix quote.
+ (BOOL)hasPrefixQuote:(NSString *)text;

/// Check if self.queryModel.queryText has suffix quote.
+ (BOOL)hasSuffixQuote:(NSString *)text;

/// Check if text hasPrefix quote.
+ (nullable NSString *)prefixQuoteOfText:(NSString *)text;

/// Check if text hasSuffix quote.
+ (nullable NSString *)suffixQuoteOfText:(NSString *)text;

/// Remove Prefix quotes
+ (NSString *)tryToRemovePrefixQuote:(NSString *)text;

/// Remove Suffix quotes
+ (NSString *)tryToRemoveSuffixQuote:(NSString *)text;

/// Count quote number in text. 动人 --> "Touching" or "Moving".
+ (NSUInteger)countQuoteNumberInText:(NSString *)text;


/// Check if text is start and end with the designated string.
+ (BOOL)isStartAndEnd:(NSString *)text with:(NSString *)start end:(NSString *)end;

/// Remove start and end string.
+ (NSString *)removeStartAndEnd:(NSString *)text with:(NSString *)start end:(NSString *)end;

/// Remove quotes. "\""
+ (NSString *)tryToRemoveQuotes:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
