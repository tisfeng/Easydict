// TTTDictionary.h
//
// Copyright (c) 2014 Mattt Thompson
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "EZLanguageModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
    TTTDictionaryEntry
 */
@interface TTTDictionaryEntry : NSObject

/// 词头
@property (readonly, nonatomic, copy) NSString *headword;

/// innerText of HTML
@property (readonly, nonatomic, copy) NSString *text;

@property (readonly, nonatomic, copy) NSString *HTML;
@property (readonly, nonatomic, copy) NSString *HTMLWithAppCSS;
@property (readonly, nonatomic, copy) NSString *HTMLWithPopoverCSS;

@end

NS_ASSUME_NONNULL_END


#pragma mark -

NS_ASSUME_NONNULL_BEGIN

/// Search word type
typedef NS_ENUM(NSUInteger, TTTDictionarySearchType) {
    TTTDictionarySearchTypeExactMatch = 0, // exact match
    TTTDictionarySearchTypePrefixMatch = 1, // forward match (prefix match)
    TTTDictionarySearchTypeLeadingMatch = 2, // partial query match (matching (leading) part of query; including ignoring diacritics, four tones in Chinese, etc)
};


/**
    TTTDictionary
 */
@interface TTTDictionary : NSObject

/**
 CFBundleDisplayName in dict's info.plist
 */
@property (readonly, nonatomic, copy) NSString *name;

/**
 CFBundleName in dict's info.plist
 */
@property (readonly, nonatomic, copy) NSString *shortName;

@property (readonly, nonatomic, assign) BOOL isUserDictionary;

@property (readonly, nonatomic, copy, nullable) NSString *identifier;
@property (readonly, nonatomic, strong) NSURL *dictionaryURL;

/// key: EZLanguage, value: language dict name
@property (class, readonly, nonatomic, copy) MMOrderedDictionary<EZLanguage, NSString *> *languageToDictionaryNameMap;

/// Get dict with CFBundleDisplayName
+ (instancetype)dictionaryNamed:(NSString *)name;

+ (NSSet<TTTDictionary *> *)availableDictionaries;

+ (NSArray<TTTDictionary *> *)activeDictionaries;

/// Dictionary directory URL, path is ~/Library/Dictionaries/
+ (NSURL *)userDictionaryDirectoryURL;

// Default searchType is exact match, 0
- (NSArray<TTTDictionaryEntry *> *)entriesForSearchTerm:(NSString *)term;

- (NSArray<TTTDictionaryEntry *> *)entriesForSearchTerm:(NSString *)term searchType:(TTTDictionarySearchType)searchType;

@end

/// @name Constants

// Simplified Chinese
extern NSString * const DCSSimplifiedChineseDictionaryName;
extern NSString * const DCSSimplifiedChineseIdiomDictionaryName;
extern NSString * const DCSSimplifiedChineseThesaurusDictionaryName;
extern NSString * const DCSSimplifiedChinese_EnglishDictionaryName;
extern NSString * const DCSSimplifiedChinese_JapaneseDictionaryName;

// Traditional Chinese
extern NSString * const DCSTraditionalChineseDictionaryName;
extern NSString * const DCSTraditionalChineseHongkongDictionaryName;
extern NSString * const DCSTraditionalChinese_EnglishDictionaryName;
extern NSString * const DCSTraditionalChinese_EnglishIdiomDictionaryName;

// English
extern NSString * const DCSNewOxfordAmericanDictionaryName;
extern NSString * const DCSOxfordAmericanWritersThesaurus;
extern NSString * const DCSOxfordDictionaryOfEnglish;
extern NSString * const DCSOxfordThesaurusOfEnglish;

// Japanese
extern NSString * const DCSJapaneseDictionaryName;
extern NSString * const DCSJapanese_EnglishDictionaryName;

// French
extern NSString * const DCSFrenchDictionaryName;
extern NSString * const DCSFrench_EnglishDictionaryName;

// German
extern NSString * const DCSGermanDictionaryName;
extern NSString * const DCSGerman_EnglishDictionaryName;

// Italian
extern NSString * const DCSItalianDictionaryName;
extern NSString * const DCSItalian_EnglishDictionaryName;

// Spanish
extern NSString * const DCSSpanishDictionaryName;
extern NSString * const DCSSpanish_EnglishDictionaryName;

// Portuguese
extern NSString * const DCSPortugueseDictionaryName;
extern NSString * const DCSPortuguese_EnglishDictionaryName;

// Dutch
extern NSString * const DCSDutchDictionaryName;
extern NSString * const DCSDutch_EnglishDictionaryName;

// Korean
extern NSString * const DCSKoreanDictionaryName;
extern NSString * const DCSKorean_EnglishDictionaryName;


extern NSString * const DCSWikipediaDictionaryName;
extern NSString * const DCSAppleDictionaryName;

NS_ASSUME_NONNULL_END
