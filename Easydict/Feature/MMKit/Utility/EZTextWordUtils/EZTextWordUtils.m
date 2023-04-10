//
//  EZTextWordUtils.m
//  Easydict
//
//  Created by tisfeng on 2023/4/6.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZTextWordUtils.h"
#import "EZLanguageManager.h"

static NSDictionary *const kQuotesDict = @{
    @"\"" : @"\"",
    @"“" : @"”",
    @"‘" : @"’",
};

@implementation EZTextWordUtils


#pragma mark - Check if text is a word, or phrase

/// If text is a Chinese or English word or phrase, need query dict.
/// Only `Word` have synonyms and antonyms, only `English Word` have parts of speech, tenses and How to remember.
+ (BOOL)shouldQueryDictionary:(NSString *)text language:(EZLanguage)langugae {
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    if ([EZLanguageManager isChineseLanguage:langugae]) {
        return [self isChineseWord:text] || [self isChinesePhrase:text];
    }
    
    if ([langugae isEqualToString:EZLanguageEnglish]) {
        return [self isEnglishWord:text] || [self isEnglishPhrase:text];
    }
    
    NSInteger wordCount = [self wordCount:text];
    if (wordCount <= 2) {
        return YES;
    }
    
    return NO;
}


/// Check if text is a English word. Note: B612 is not a word.
+ (BOOL)isEnglishWord:(NSString *)text {
    text = [self tryToRemoveQuotes:text];
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    NSString *pattern = @"^[a-zA-Z]+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:text];
}

/// Check if text is a English phrase, like B612, 9527, Since they are detected as English, should query dict, but don't have pos.
+ (BOOL)isEnglishPhrase:(NSString *)text {
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    NSInteger wordCount = [self wordCount:text];
    
    if (wordCount <= 2) {
        return YES;
    }
    
    return NO;
}

/// Use NLTokenizer to check if text is a word.
+ (BOOL)isWord:(NSString *)text {
    text = [self tryToRemoveQuotes:text];
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    NSInteger wordCount = [self wordCount:text];
    if (wordCount == 1) {
        return YES;
    }
    return NO;
}

/// Count word count of text.
+ (NSInteger)wordCount:(NSString *)text {
    NLTokenizer *tokenizer = [[NLTokenizer alloc] initWithUnit:NLTokenUnitWord];
    tokenizer.string = text;
    __block NSInteger count = 0;
    [tokenizer enumerateTokensInRange:NSMakeRange(0, text.length) usingBlock:^(NSRange tokenRange, NLTokenizerAttributes attributes, BOOL *stop) {
        count++;
    }];
    return count;
}

/// Use NLTagger to check if text is a word.
+ (BOOL)isWord2:(NSString *)text {
    text = [self tryToRemoveQuotes:text];
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    // NLTagSchemeLanguage
    NLTagger *tagger = [[NLTagger alloc] initWithTagSchemes:@[ NLTagSchemeTokenType ]];
    [tagger setString:text];
    __block BOOL result = NO;
    [tagger enumerateTagsInRange:NSMakeRange(0, text.length) unit:NLTokenUnitWord scheme:NLTagSchemeLexicalClass options:0 usingBlock:^(NLTag tag, NSRange tokenRange, BOOL *stop) {
        if (tokenRange.length == text.length && [tag isEqualToString:NLTagWord]) {
            result = YES;
        }
        *stop = YES;
    }];
    return result;
}

/// Cannot use to check a word, like 'love'.
+ (NSArray<NLTag> *)taggedWordsInText:(NSString *)text {
    // Apple Docs: https://developer.apple.com/documentation/naturallanguage/identifying_parts_of_speech?language=objc
    
    NLTagScheme tagScheme = NLTagSchemeLexicalClass;
    NLTaggerOptions options = NLTaggerOmitPunctuation | NLTaggerOmitWhitespace;
    NSRange range = NSMakeRange(0, text.length);

    NLTagger *tagger = [[NLTagger alloc] initWithTagSchemes:@[ tagScheme ]];
    tagger.string = text;
//    [tagger setLanguage:NLLanguageEnglish range:range];
    
    NSArray<NLTag> *tags = [tagger tagsInRange:range
                                          unit:NLTokenUnitWord
                                        scheme:tagScheme
                                       options:options
                                   tokenRanges:nil];
    /**
     The ripe taste of cheese improves with age.
     
     "Determiner",
     "Adjective",
     "Noun",
     "Preposition",
     "Noun",
     "Verb",
     "Preposition",
     "Noun"
     */
    NSLog(@"tags: %@", tags);
    
    [tagger enumerateTagsInRange:range
                            unit:NLTokenUnitWord
                          scheme:tagScheme
                         options:options
                      usingBlock:^(NLTag _Nullable tag, NSRange tokenRange, BOOL *_Nonnull stop) {
        if (tag != nil) {
            NSString *token = [text substringWithRange:tokenRange];
            NSLog(@"%@: %@", token, tag);
        }
    }];
    
    return tags;
}

/// Use NSSpellChecker to check word spell.
+ (BOOL)isSpelledCorrectly:(NSString *)word {
    NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
    NSRange misspelledRange = [spellChecker checkSpellingOfString:word startingAt:0];
    return misspelledRange.location == NSNotFound;
}

/// Check if text is a Chinese word, length <= 4, 倾国倾城
+ (BOOL)isChineseWord:(NSString *)text {
    text = [self tryToRemoveQuotes:text];
    if (text.length > 4) {
        return NO;
    }
    
    return [self isChineseText:text];
}

/// Check if text is a Chinese phrase, length <= 5, 今宵别梦寒
+ (BOOL)isChinesePhrase:(NSString *)text {
    text = [self tryToRemoveQuotes:text];
    if (text.length > 5) {
        return NO;
    }
    
    return [self isChineseText:text];
}

+ (BOOL)isChineseText:(NSString *)text {
    NSString *pattern = @"^[\u4e00-\u9fa5]+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:text];
}

+ (BOOL)isChineseText2:(NSString *)text {
    NSString *pattern = @"^[\u4e00-\u9fa5]+$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])];
    return numberOfMatches > 0;
}

/// Check if text is a sentence, use NLTokenizer.
+ (BOOL)isSentence:(NSString *)text {
    NSInteger count = [self sentenceCount:text];
    return count == 1;
}

/// Sentence count of text.
+ (NSInteger)sentenceCount:(NSString *)text {
    NLTokenizer *tokenizer = [[NLTokenizer alloc] initWithUnit:NLTokenUnitSentence];
    tokenizer.string = text;
    __block NSInteger count = 0;
    [tokenizer enumerateTokensInRange:NSMakeRange(0, text.length) usingBlock:^(NSRange tokenRange, NLTokenizerAttributes attributes, BOOL *stop) {
        count++;
    }];
    return count;
}



#pragma mark - Handle extra quotes.

/// Check if self.queryModel.queryText has prefix quote.
+ (BOOL)hasPrefixQuote:(NSString *)text {
    if ([self prefixQuoteOfText:text]) {
        return YES;
    }
    return NO;
}

/// Check if self.queryModel.queryText has suffix quote.
+ (BOOL)hasSuffixQuote:(NSString *)text {
    if ([self suffixQuoteOfText:text]) {
        return YES;
    }
    return NO;
}

/// Check if text hasPrefix quote.
+ (nullable NSString *)prefixQuoteOfText:(NSString *)text {
    NSArray *leftQuotes = kQuotesDict.allKeys; // @[ @"\"", @"“", @"‘" ];
    for (NSString *quote in leftQuotes) {
        if ([text hasPrefix:quote]) {
            return quote;
        }
    }
    return nil;
}

/// Check if text hasSuffix quote.
+ (nullable NSString *)suffixQuoteOfText:(NSString *)text {
    NSArray *rightQuotes = kQuotesDict.allValues; // @[ @"\"", @"”", @"’" ];
    for (NSString *quote in rightQuotes) {
        if ([text hasSuffix:quote]) {
            return quote;
        }
    }
    return nil;
}

/// Remove Prefix quotes
+ (NSString *)tryToRemovePrefixQuote:(NSString *)text {
    if ([self prefixQuoteOfText:text]) {
        return [text substringFromIndex:1];
    }
    
    return text;
}

/// Remove Suffix quotes
+ (NSString *)tryToRemoveSuffixQuote:(NSString *)text {
    if ([self suffixQuoteOfText:text]) {
        return [text substringToIndex:text.length - 1];
    }
    
    return text;
}

/// Count quote number in text. 动人 --> "Touching" or "Moving".
+ (NSUInteger)countQuoteNumberInText:(NSString *)text {
    NSUInteger count = 0;
    NSArray *leftQuotes = kQuotesDict.allKeys;
    NSArray *rightQuotes = kQuotesDict.allValues;
    NSArray *quotes = [leftQuotes arrayByAddingObjectsFromArray:rightQuotes];
    
    for (NSUInteger i = 0; i < text.length; i++) {
        NSString *character = [text substringWithRange:NSMakeRange(i, 1)];
        if ([quotes containsObject:character]) {
            count++;
        }
    }
    
    return count;
}


/// Check if text is start and end with the designated string.
+ (BOOL)isStartAndEnd:(NSString *)text with:(NSString *)start end:(NSString *)end {
    if (text.length < 2) {
        return NO;
    }
    return [text hasPrefix:start] && [text hasSuffix:end];
}

/// Remove start and end string.
+ (NSString *)removeStartAndEnd:(NSString *)text with:(NSString *)start end:(NSString *)end {
    if ([self isStartAndEnd:text with:start end:end]) {
        return [text substringWithRange:NSMakeRange(start.length, text.length - start.length - end.length)];
    }
    return text;
}

/// Remove quotes. "\""
+ (NSString *)tryToRemoveQuotes:(NSString *)text {
    NSArray *quotes = [kQuotesDict allKeys];
    for (NSString *quote in quotes) {
        text = [self removeStartAndEnd:text with:quote end:kQuotesDict[quote]];
    }
    return text;
}


@end
