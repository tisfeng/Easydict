//
//  NSString+EZCharacterSet.m
//  Easydict
//
//  Created by tisfeng on 2023/6/2.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZUtils.h"
#import "EZLanguageManager.h"

static NSArray *const kEndPunctuationMarks = @[ @"。", @"？", @"！", @"?", @".", @"!", @";", @":", @"：", @"...", @"……" ];

static NSDictionary *const kQuotesDict = @{
    @"\"" : @"\"",
    @"“" : @"”",
    @"‘" : @"’",
    @"'" : @"'",
    @"`" : @"`",
    @"「" : @"」",
};

@implementation NSString (EZUtils)

/// Check if it is a single letter of the alphabet, like 'a', 'A'
- (BOOL)isAlphabet {
    if (self.length != 1) {
        return NO;
    }
    
    NSString *regex = @"[a-zA-Z]";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:self];
}

- (BOOL)isLetterString {
    NSCharacterSet *letterCharacterSet = [NSCharacterSet letterCharacterSet];
    NSCharacterSet *stringCharacterSet = [NSCharacterSet characterSetWithCharactersInString:self];
    return [letterCharacterSet isSupersetOfSet:stringCharacterSet];
}

/// Check if lowercaseString, like
- (BOOL)isLowercaseLetter {
    NSCharacterSet *lowercaseCharSet = [NSCharacterSet lowercaseLetterCharacterSet];
    NSCharacterSet *stringCharacterSet = [NSCharacterSet characterSetWithCharactersInString:self];
    return [lowercaseCharSet isSupersetOfSet:stringCharacterSet];
}

/// Check if first char is lowercaseString
- (BOOL)isLowercaseFirstChar {
    if (self.length == 0) {
        return NO;
    }
    
    NSString *firstChar = [self substringToIndex:1];
    return [firstChar isLowercaseLetter];
}

- (BOOL)isUppercaseLetter {
    NSCharacterSet *uppercaseCharSet = [NSCharacterSet uppercaseLetterCharacterSet];
    NSCharacterSet *stringCharacterSet = [NSCharacterSet characterSetWithCharactersInString:self];
    return [uppercaseCharSet isSupersetOfSet:stringCharacterSet];
}

/// Check if first char is uppercaseString
- (BOOL)isUppercaseFirstChar {
    if (self.length == 0) {
        return NO;
    }
    
    NSString *firstChar = [self substringToIndex:1];
    return [firstChar isUppercaseLetter];
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

/// Check if the first char of text contains EZPointCharacterList element.
- (BOOL)isPointFirstChar {
    NSString *firstChar = [self firstChar];
    return [EZPointCharacterList containsObject:firstChar];
}

- (BOOL)isDashFirstWord {
    NSString *firstWord = [self firstWord];
    return [EZDashCharacterList containsObject:firstWord];
}
- (BOOL)isDashFirstChar {
    NSString *firstChar = [self firstChar];
    return [EZDashCharacterList containsObject:firstChar];
}

- (BOOL)isNumberFirstWord {
    NSString *firstWord = [self firstWord];
    
    NSString *dot = @".";
    if ([firstWord containsString:dot]) {
        NSString *number = [firstWord componentsSeparatedByString:dot].firstObject;
        if (number) {
            return [self isNumbers];
        }
    }
    return NO;
}

- (BOOL)isListTypeFirstWord {
    BOOL isList = [self isPointFirstWord] || [self isDashFirstWord] || [self isNumberFirstWord];
    
    // Since ocr may be incorrect, we should check if the first char is a list type.
    if (!isList) {
        isList = [self isPointFirstChar] || [self isDashFirstChar];
    }
    
    return isList;
}

#pragma mark -

#pragma mark - Check if text is a word, or phrase

- (EZQueryTextType)queryTypeWithLanguage:(EZLanguage)language {
    BOOL isQueryDictionary = [self shouldQueryDictionaryWithLanguage:language];
    if (isQueryDictionary) {
        return EZQueryTextTypeDictionary;
    }
    
    BOOL isEnglishText = [language isEqualToString:EZLanguageEnglish];
    BOOL isQueryEnglishSentence = [self shouldQuerySentenceWithLanguage:language];
    if (isQueryEnglishSentence && isEnglishText) {
        return EZQueryTextTypeSentence;
    }
    
    return EZQueryTextTypeTranslation;
}

- (BOOL)shouldQueryDictionaryWithLanguage:(EZLanguage)language {
    if (self.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    if ([EZLanguageManager.shared isChineseLanguage:language]) {
        return [self isChineseWord] || [self isChinesePhrase];
    }
    
    if ([language isEqualToString:EZLanguageEnglish]) {
        return [self isEnglishWord] || [self isEnglishPhrase];
    }
    
    NSInteger wordCount = [self wordCount];
    if (wordCount <= 2) {
        return YES;
    }
    
    return NO;
}

- (BOOL)shouldQuerySentenceWithLanguage:(EZLanguage)language {
    if ([self shouldQueryDictionaryWithLanguage:language]) {
        return NO;
    }
    
    return [self isSentence];
}

- (BOOL)isSentence {
    NSInteger count = [self sentenceCount];
    return count == 1;
}

- (NSInteger)sentenceCount {
    NLTokenizer *tokenizer = [[NLTokenizer alloc] initWithUnit:NLTokenUnitSentence];
    tokenizer.string = self;
    __block NSInteger count = 0;
    [tokenizer enumerateTokensInRange:NSMakeRange(0, self.length) usingBlock:^(NSRange tokenRange, NLTokenizerAttributes attributes, BOOL *stop) {
        count++;
    }];
    return count;
}

- (BOOL)isEnglishWordWithLanguage:(EZLanguage)language {
    BOOL isEnglish = [language isEqualToString:EZLanguageEnglish];
    BOOL isEnglishWord = isEnglish && [self isEnglishWord];
    return isEnglishWord;
}

- (BOOL)isEnglishWord {
    NSString *text = [self tryToRemoveQuotes];
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    NSString *pattern = @"^[a-zA-Z]+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:text];
}

- (BOOL)isEnglishPhrase {
    if (self.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    NSInteger wordCount = [self wordCount];
    if (wordCount <= 2) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isWord {
    NSString *text = [self tryToRemoveQuotes];
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    NSInteger wordCount = [self wordCount];
    if (wordCount == 1) {
        return YES;
    }
    return NO;
}

- (NSInteger)wordCount {
    NLTokenizer *tokenizer = [[NLTokenizer alloc] initWithUnit:NLTokenUnitWord];
    tokenizer.string = self;
    __block NSInteger count = 0;
    [tokenizer enumerateTokensInRange:NSMakeRange(0, self.length) usingBlock:^(NSRange tokenRange, NLTokenizerAttributes attributes, BOOL *stop) {
        count++;
    }];
    return count;
}

- (BOOL)isWord2 {
    NSString *text = [self tryToRemoveQuotes];
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    NLTagger *tagger = [[NLTagger alloc] initWithTagSchemes:@[ NLTagSchemeTokenType ]];
    [tagger setString:self];
    __block BOOL result = NO;
    [tagger enumerateTagsInRange:NSMakeRange(0, self.length) unit:NLTokenUnitWord scheme:NLTagSchemeLexicalClass options:0 usingBlock:^(NLTag tag, NSRange tokenRange, BOOL *stop) {
        if (tokenRange.length == self.length && [tag isEqualToString:NLTagWord]) {
            result = YES;
        }
        *stop = YES;
    }];
    return result;
}

- (NSArray<NLTag> *)taggedWordsInText {
    NLTagScheme tagScheme = NLTagSchemeLexicalClass;
    NLTaggerOptions options = NLTaggerOmitPunctuation | NLTaggerOmitWhitespace;
    NSRange range = NSMakeRange(0, self.length);

    NLTagger *tagger = [[NLTagger alloc] initWithTagSchemes:@[ tagScheme ]];
    tagger.string = self;
    
    NSArray<NLTag> *tags = [tagger tagsInRange:range
                                          unit:NLTokenUnitWord
                                        scheme:tagScheme
                                       options:options
                                   tokenRanges:nil];
    
    return tags;
}

- (BOOL)isSpelledCorrectly {
    NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
    NSRange wordRange = NSMakeRange(0, [self length]);
    NSString *language = [spellChecker language];
    NSString *correctedWord = [spellChecker correctionForWordRange:wordRange inString:self language:language inSpellDocumentWithTag:0];
    BOOL isCorrect = correctedWord == nil;
    if (!isCorrect) {
        NSArray *guessWords = [spellChecker guessesForWordRange:wordRange inString:self language:language inSpellDocumentWithTag:0];
        NSLog(@"guessWords: %@", guessWords);
    }
    return isCorrect;
}

- (BOOL)isChineseWord {
    NSString *text = [self tryToRemoveQuotes];
    if (text.length > 4) {
        return NO;
    }
    return [self isChineseText];
}

- (BOOL)isChinesePhrase {
    NSString *text = [self tryToRemoveQuotes];
    if (text.length > 5) {
        return NO;
    }
    return [self isChineseText];
}

- (BOOL)isChineseText {
    NSString *pattern = @"^[\u4e00-\u9fa5]+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:self];
}

- (BOOL)isChineseText2 {
    NSString *pattern = @"^[\u4e00-\u9fa5]+$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:self options:0 range:NSMakeRange(0, self.length)];
    return numberOfMatches > 0;
}

- (BOOL)isNumbers {
    NSString *regex = @"^[0-9]+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:self];
}

#pragma mark - Handle extra quotes.

- (BOOL)hasPrefixQuote {
    if ([self prefixQuote]) {
        return YES;
    }
    return NO;
}

- (BOOL)hasSuffixQuote {
    if ([self suffixQuote]) {
        return YES;
    }
    return NO;
}

- (NSString *)prefixQuote {
    NSArray *leftQuotes = kQuotesDict.allKeys;
    for (NSString *quote in leftQuotes) {
        if ([self hasPrefix:quote]) {
            return quote;
        }
    }
    return nil;
}

- (NSString *)suffixQuote {
    NSArray *rightQuotes = kQuotesDict.allValues;
    for (NSString *quote in rightQuotes) {
        if ([self hasSuffix:quote]) {
            return quote;
        }
    }
    return nil;
}

- (NSString *)tryToRemovePrefixQuote {
    NSString *prefixQuote = [self prefixQuote];
    if (prefixQuote) {
        return [self substringFromIndex:prefixQuote.length];
    }
    
    return self;
}

- (NSString *)tryToRemoveSuffixQuote {
    NSString *suffixQuote = [self suffixQuote];
    if (suffixQuote) {
        return [self substringToIndex:self.length - suffixQuote.length];
    }
    
    return self;
}

- (NSUInteger)countQuoteNumberInText {
    NSUInteger count = 0;
    NSArray *leftQuotes = kQuotesDict.allKeys;
    NSArray *rightQuotes = kQuotesDict.allValues;
    NSArray *quotes = [leftQuotes arrayByAddingObjectsFromArray:rightQuotes];
    
    for (NSUInteger i = 0; i < self.length; i++) {
        NSString *character = [self substringWithRange:NSMakeRange(i, 1)];
        if ([quotes containsObject:character]) {
            count++;
        }
    }
    
    return count;
}

- (BOOL)isStartAndEndWith:(NSString *)start end:(NSString *)end {
    if (self.length < 2) {
        return NO;
    }
    return [self hasPrefix:start] && [self hasSuffix:end];
}

- (NSString *)removeStartAndEndWith:(NSString *)start end:(NSString *)end {
    if ([self isStartAndEndWith:start end:end]) {
        return [self substringWithRange:NSMakeRange(start.length, self.length - start.length - end.length)];
    }
    return self;
}

- (NSString *)tryToRemoveQuotes {
    NSArray *quotes = [kQuotesDict allKeys];
    NSString *text = self;
    for (NSString *quote in quotes) {
        text = [text removeStartAndEndWith:quote end:kQuotesDict[quote]];
    }
    return text;
}

- (BOOL)hasQuotesPair {
    NSString *text = [self tryToRemoveQuotes];
    return ![text isEqualToString:self];
}


#pragma mark - Remove designated characters.

- (NSString *)removeNonNormalCharacters {
    NSString *text = [self removeWhitespaceAndNewlineCharacters];
    text = [text removePunctuationCharacters];
    text = [text removeSymbolCharacterSet];
    text = [text removeNumbers];
    text = [text removeNonBaseCharacterSet];
    return text;
}

- (NSString *)removeWhitespaceAndNewlineCharacters {
    NSString *text = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    text = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return text;
}

- (NSString *)removePunctuationCharacters {
    NSCharacterSet *punctuationCharacterSet = [NSCharacterSet punctuationCharacterSet];
    NSString *result = [[self componentsSeparatedByCharactersInSet:punctuationCharacterSet] componentsJoinedByString:@""];
    return result;
}

- (NSString *)removePunctuationCharacters2 {
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"~`!@#$%^&*()-_+={}[]|\\;:'\",<.>/?·~！@#￥%……&*（）——+={}【】、|；：‘“，。、《》？"];
    NSCharacterSet *punctuationCharSet = [NSCharacterSet punctuationCharacterSet];
    NSMutableCharacterSet *finalCharSet = [punctuationCharSet mutableCopy];
    [finalCharSet formUnionWithCharacterSet:charSet];
    NSString *text = [[self componentsSeparatedByCharactersInSet:finalCharSet] componentsJoinedByString:@""];
    return text;
}

- (NSString *)removeNumbers {
    NSCharacterSet *charSet = [NSCharacterSet decimalDigitCharacterSet];
    NSString *text = [[self componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

- (NSString *)removeSymbolCharacterSet {
    NSCharacterSet *charSet = [NSCharacterSet symbolCharacterSet];
    NSString *text = [[self componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

- (NSString *)removeControlCharacterSet {
    NSCharacterSet *charSet = [NSCharacterSet controlCharacterSet];
    NSString *text = [[self componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

- (NSString *)removeIllegalCharacterSet {
    NSCharacterSet *charSet = [NSCharacterSet illegalCharacterSet];
    NSString *text = [[self componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

- (NSString *)removeNonBaseCharacterSet {
    NSCharacterSet *charSet = [NSCharacterSet nonBaseCharacterSet];
    NSString *text = [[self componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

- (NSString *)removeAlphabet {
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    NSString *text = [[self componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

- (NSString *)removeAlphabet2 {
    NSString *regex = @"[a-zA-Z]";
    NSString *text = [self stringByReplacingOccurrencesOfString:regex withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, self.length)];
    return text;
}

- (NSString *)removeLetters {
    NSCharacterSet *charSet = [NSCharacterSet letterCharacterSet];
    NSString *text = [[self componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

- (NSString *)removeAlphabetAndNumbers {
    NSCharacterSet *charSet = [NSCharacterSet alphanumericCharacterSet];
    NSString *text = [[self componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

@end
