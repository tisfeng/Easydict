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

/**
 
 */
@interface TTTDictionaryEntry : NSObject

/**
 
 */
@property (readonly, nonatomic, copy) NSString *headword;

/**
 
 */
@property (readonly, nonatomic, copy) NSString *text;

/**
 
 */
@property (readonly, nonatomic, copy) NSString *HTML;

@property (readonly, nonatomic, copy) NSString *HTMLWithAppCSS;


@end

#pragma mark -

/**
 
 */
@interface TTTDictionary : NSObject

/**
 
 */
@property (readonly, nonatomic, copy) NSString *name;

/**
 
 */
@property (readonly, nonatomic, copy) NSString *shortName;

/**
 
 */
+ (NSSet<TTTDictionary *> *)availableDictionaries;

/**
 
 */
+ (instancetype)dictionaryNamed:(NSString *)name;

/**
 
 */
- (NSArray<TTTDictionaryEntry *> *)entriesForSearchTerm:(NSString *)term;

@end

/// @name Constants

// Simplified Chinese
extern NSString * const DCSSimplifiedChinese_EnglishDictionaryName;
extern NSString * const DCSSimplifiedChineseDictionaryName;
extern NSString * const DCSSimplifiedChineseIdiomDictionaryName;
extern NSString * const DCSSimplifiedChineseThesaurusDictionaryName;
extern NSString * const DCSSimplifiedChinese_JapaneseDictionaryName;

//// Traditional Chinese
extern NSString * const DCSTraditionalChinese_EnglishDictionaryName;
extern NSString * const DCSTraditionalChineseHongkongDictionaryName;
extern NSString * const DCSTraditionalChinese_EnglishIdiomDictionaryName;
extern NSString * const DCSTraditionalChineseDictionaryName;

//// English
extern NSString * const DCSNewOxfordAmericanDictionaryName;
extern NSString * const DCSOxfordAmericanWritersThesaurus;
extern NSString * const DCSOxfordDictionaryOfEnglish;
extern NSString * const DCSOxfordThesaurusOfEnglish;

//// Japanese
extern NSString * const DCSJapaneseDictionaryName;
extern NSString * const DCSJapanese_EnglishDictionaryName;

extern NSString * const DCSWikipediaDictionaryName;
extern NSString * const DCSAppleDictionaryName;


extern NSString * const DCSDutchDictionaryName;
extern NSString * const DCSFrenchDictionaryName;
extern NSString * const DCSGermanDictionaryName;
extern NSString * const DCSItalianDictionaryName;
extern NSString * const DCSJapaneseSupaDaijirinDictionaryName;
extern NSString * const DCSKoreanDictionaryName;
extern NSString * const DCSKorean_EnglishDictionaryName;
extern NSString * const DCSSpanishDictionaryName;
extern NSString * const DCSWikipediaDictionaryName;
