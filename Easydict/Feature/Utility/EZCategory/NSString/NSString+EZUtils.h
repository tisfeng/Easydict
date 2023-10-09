//
//  NSString+EZCharacterSet.h
//  Easydict
//
//  Created by tisfeng on 2023/6/2.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageModel.h"
#import <NaturalLanguage/NaturalLanguage.h>
#import "EZEnumTypes.h"

NS_ASSUME_NONNULL_BEGIN

static NSArray *const EZPointCharacterList = @[ @"•", @"‧", @"∙"];
static NSArray *const EZDashCharacterList = @[ @"—", @"-", @"–" ];

@interface NSString (EZUtils)

/// Check if it is a single letter of the alphabet, like 'a', 'A'
- (BOOL)isAlphabet;

- (BOOL)isLetterString;

/// Check if lowercaseString, like 'a'
- (BOOL)isLowercaseLetter;
- (BOOL)isLowercaseFirstChar;

- (BOOL)isUppercaseLetter;
- (BOOL)isUppercaseFirstChar;


/// Get first word of string
- (NSString *)firstWord;

/// Get last word of string
- (NSString *)lastWord;


/// Check if text is a end punctuation mark.
- (BOOL)hasEndPunctuationSuffix;

- (nullable NSString *)firstChar;

- (nullable NSString *)lastChar;

- (BOOL)isListTypeFirstWord;

#pragma mark -


- (EZQueryTextType)queryTypeWithLanguage:(EZLanguage)language;

- (BOOL)shouldQueryDictionaryWithLanguage:(EZLanguage)language;

- (BOOL)shouldQuerySentenceWithLanguage:(EZLanguage)language;

- (BOOL)isEnglishWordWithLanguage:(EZLanguage)language;

- (BOOL)isEnglishWord;

- (BOOL)isEnglishPhrase;

- (BOOL)isWord;

- (NSInteger)wordCount;

- (BOOL)isWord2;

- (NSArray<NLTag> *)taggedWordsInText;

- (BOOL)isSpelledCorrectly;

- (BOOL)isChineseWord;

- (BOOL)isChinesePhrase;

- (BOOL)isChineseText;

- (BOOL)isChineseText2;

- (BOOL)isSentence;

- (NSInteger)sentenceCount;


- (BOOL)isNumbers;

- (BOOL)hasPrefixQuote;

- (BOOL)hasSuffixQuote;

- (NSString *)prefixQuote;

- (NSString *)suffixQuote;

- (NSString *)tryToRemovePrefixQuote;

- (NSString *)tryToRemoveSuffixQuote;

- (NSUInteger)countQuoteNumberInText;

- (BOOL)isStartAndEndWith:(NSString *)start end:(NSString *)end;

- (NSString *)removeStartAndEndWith:(NSString *)start end:(NSString *)end;

- (NSString *)tryToRemoveQuotes;


- (NSString *)removeNonNormalCharacters;

- (NSString *)removeWhitespaceAndNewlineCharacters;

- (NSString *)removePunctuationCharacters;

- (NSString *)removePunctuationCharacters2;

- (NSString *)removeNumbers;

- (NSString *)removeSymbolCharacterSet;

- (NSString *)removeControlCharacterSet;

- (NSString *)removeIllegalCharacterSet;

- (NSString *)removeNonBaseCharacterSet;

- (NSString *)removeAlphabet;

- (NSString *)removeAlphabet2;

- (NSString *)removeLetters;

- (NSString *)removeAlphabetAndNumbers;

@end

NS_ASSUME_NONNULL_END
