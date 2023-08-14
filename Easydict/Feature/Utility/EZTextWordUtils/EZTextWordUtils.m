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


/// Get query type of text.
+ (EZQueryTextType)queryTypeOfText:(NSString *)text language:(EZLanguage)langugae {
    BOOL isQueryDictionary = [self shouldQueryDictionary:text language:langugae];
    if (isQueryDictionary) {
        return EZQueryTextTypeDictionary;
    }
    
    BOOL isEnglishText = [langugae isEqualToString:EZLanguageEnglish];
    BOOL isQueryEnglishSentence = [self shouldQuerySentence:text language:langugae];
    if (isQueryEnglishSentence && isEnglishText) {
        return EZQueryTextTypeSentence;
    }
    
    return EZQueryTextTypeTranslation;
}

/// If text is a Chinese or English word or phrase, need to query dict.
+ (BOOL)shouldQueryDictionary:(NSString *)text language:(EZLanguage)langugae {
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    if ([EZLanguageManager.shared isChineseLanguage:langugae]) {
        return [self isChineseWord:text] || [self isChinesePhrase:text];
    }
    
    if ([langugae isEqualToString:EZLanguageEnglish]) {
        return [self isEnglishWord:text] || [self isEnglishPhrase:text];
    }
    
    NSInteger wordCount = [self wordCount:text];
    // ???: かわいい女の子 wordCount is 2 😢
    if (wordCount <= 2) {
        return YES;
    }
    
    return NO;
}

/// text should not a word, and then text is a sentence.
+ (BOOL)shouldQuerySentence:(NSString *)text language:(EZLanguage)langugae {
    if ([self shouldQueryDictionary:text language:langugae]) {
        return NO;
    }
    
    return [self isSentence:text];
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
//        NSLog(@"sentence: %@", [text substringWithRange:tokenRange]);
        count++;
    }];
    return count;
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

+ (BOOL)isEnglishText:(NSString *)text {
    text = [self tryToRemoveQuotes:text];
    
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
//        NSString *charString = [text substringWithRange:tokenRange];
//        NSLog(@"char: %@", charString);
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
    NSRange wordRange = NSMakeRange(0, [word length]);
    NSString *language = [spellChecker language]; // en
    /**
     lowlatency --> low latency
     slow-read --> slowed
     */
    NSString *correctedWord = [spellChecker correctionForWordRange:wordRange inString:word language:language inSpellDocumentWithTag:0];
    BOOL isCorrect = correctedWord == nil;
    if (!isCorrect) {
        /**
         "low latency",  "low-latency"
         
         "slower",
         "slowed",
         "slobbered",
         "slow-read",
         "slow read"
         */
        NSArray *guessWords = [spellChecker guessesForWordRange:wordRange inString:word language:language inSpellDocumentWithTag:0];
        NSLog(@"guessWords: %@", guessWords);
    }
    return isCorrect;
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

/// !!!: This method is not accurate. 権 --> zh
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

/// Check if it is a single letter of the alphabet.
+ (BOOL)isAlphabet:(NSString *)charString {
    if (charString.length != 1) {
        return NO;
    }
    
    NSString *regex = @"[a-zA-Z]";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:charString];
}

/// Check if text is numbers.
+ (BOOL)isNumbers:(NSString *)text {
    NSString *regex = @"^[0-9]+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:text];
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
    NSString *prefixQuote = [self prefixQuoteOfText:text];
    if (prefixQuote) {
        NSString *newText = [text substringFromIndex:prefixQuote.length];
        return newText;
    }
    
    return text;
}

/// Remove Suffix quotes
+ (NSString *)tryToRemoveSuffixQuote:(NSString *)text {
    NSString *suffixQuote = [self suffixQuoteOfText:text];
    if (suffixQuote) {
        NSString *newText = [text substringToIndex:text.length - suffixQuote.length];
        return newText;
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

#pragma mark - Remove desingated characters.

/// Remove all whitespace, punctuation, symbol and number characters.
+ (NSString *)removeNonNormalCharacters:(NSString *)string {
    NSString *text = [self removeWhitespaceAndNewlineCharacters:string];
    text = [self removePunctuationCharacters:text];
    text = [self removeSymbolCharacterSet:text];
    text = [self removeNumbers:text];
    text = [self removeNonBaseCharacterSet:text];
    return text;
}

/// Remove all whitespace and newline characters, including whitespace in the middle of the string.
+ (NSString *)removeWhitespaceAndNewlineCharacters:(NSString *)string {
    NSString *text = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    text = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return text;
}

/// Remove all punctuation characters, including English and Chinese.
+ (NSString *)removePunctuationCharacters:(NSString *)string {
    NSCharacterSet *punctuationCharacterSet = [NSCharacterSet punctuationCharacterSet];
    NSString *result = [[string componentsSeparatedByCharactersInSet:punctuationCharacterSet] componentsJoinedByString:@""];
    return result;
}

+ (NSString *)removePunctuationCharacters2:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"~`!@#$%^&*()-_+={}[]|\\;:'\",<.>/?·~！@#￥%……&*（）——+={}【】、|；：‘“，。、《》？"];
    NSCharacterSet *punctuationCharSet = [NSCharacterSet punctuationCharacterSet];
    NSMutableCharacterSet *finalCharSet = [punctuationCharSet mutableCopy];
    [finalCharSet formUnionWithCharacterSet:charSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:finalCharSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all numbers.
+ (NSString *)removeNumbers:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet decimalDigitCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all symbolCharacterSet. such as $, not including punctuationCharacterSet.
+ (NSString *)removeSymbolCharacterSet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet symbolCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all controlCharacterSet.
+ (NSString *)removeControlCharacterSet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet controlCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all illegalCharacterSet.
+ (NSString *)removeIllegalCharacterSet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet illegalCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all nonBaseCharacterSet.
+ (NSString *)removeNonBaseCharacterSet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet nonBaseCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all alphabet.
+ (NSString *)removeAlphabet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all alphabet, use regex.
+ (NSString *)removeAlphabet2:(NSString *)string {
    NSString *regex = @"[a-zA-Z]";
    NSString *text = [string stringByReplacingOccurrencesOfString:regex withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, string.length)];
    return text;
}

/// Remove all letters. Why "我123abc" will return "123"? Chinese characters are also letters ??
+ (NSString *)removeLetters:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet letterCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all alphabet and numbers.
+ (NSString *)removeAlphabetAndNumbers:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet alphanumericCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Print NSCharacterSet object.
+ (void)printCharacterSet:(NSCharacterSet *)charSet {
    NSMutableArray *array = [NSMutableArray array];
    for (int plane = 0; plane <= 16; plane++) {
        if ([charSet hasMemberInPlane:plane]) {
            UTF32Char c;
            for (c = plane << 16; c < (plane + 1) << 16; c++) {
                if ([charSet longCharacterIsMember:c]) {
                    UTF32Char c1 = OSSwapHostToLittleInt32(c); // To make it byte-order safe
                    NSString *s = [[NSString alloc] initWithBytes:&c1 length:4 encoding:NSUTF32LittleEndianStringEncoding];
                    [array addObject:s];
                }
            }
        }
    }
    NSLog(@"charSet: %@", array);
}

@end
