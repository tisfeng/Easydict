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


#pragma mark - Check if text is a word, or phrase

- (EZQueryTextType)queryTypeWithLanguage:(EZLanguage)language maxWordCount:(NSInteger)maxWordCount;

- (BOOL)shouldQueryDictionaryWithLanguage:(EZLanguage)language maxWordCount:(NSInteger)maxWordCount;

- (BOOL)shouldQuerySentenceWithLanguage:(EZLanguage)language;

- (BOOL)isEnglishWordWithLanguage:(EZLanguage)language;

- (BOOL)isEnglishWord;

- (BOOL)isEnglishWordWithMaxWordLength:(NSUInteger)maxWordLength;

- (BOOL)isEnglishPhrase;

- (BOOL)isWord;

- (NSInteger)wordCount;

- (BOOL)isSingleWord;

- (BOOL)isWord2;

/// Words lexical
- (NSArray<NLTag> *)taggedWordsInText;

/// Tokenizing text
- (NSArray<NSString *> *)wordsInText;

/// Word at index.
- (nullable NSString *)wordAtIndex:(NSInteger)characterIndex;

/// Check English word is spelled correctly
- (BOOL)isSpelledCorrectly;

- (BOOL)isSpelledCorrectly:(nullable NSString *)language;

- (nullable NSArray<NSString *> *)guessedWords;

- (BOOL)isChineseWord;

- (BOOL)isChinesePhrase;

- (BOOL)isChineseText;

- (BOOL)isChineseText2;

- (BOOL)isSentence;

- (NSInteger)sentenceCount;


- (BOOL)isNumbers;

#pragma mark - Handle extra quotes.

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

- (BOOL)hasQuotesPair;

#pragma mark - Remove designated characters.

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
