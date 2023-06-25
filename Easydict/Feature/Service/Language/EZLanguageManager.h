//
//  EZLanguage.h
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZLanguageManager : NSObject

+ (instancetype)shared;

/// System languages, ["zh-Hans-CN", "en-CN"]
@property (nonatomic, copy, readonly) NSArray<EZLanguage> *systemPreferredLanguages;
@property (nonatomic, copy, readonly) NSArray<EZLanguage> *preferredTwoLanguages;
@property (nonatomic, copy, readonly) EZLanguage firstLanguage;
@property (nonatomic, copy, readonly) EZLanguage secondLanguage;


- (nullable EZLanguageModel *)languageModelFromLanguage:(EZLanguage)language;

/// Get target language with source language
- (EZLanguage)targetLanguageWithSourceLanguage:(EZLanguage)sourceLanguage;

//+ (NSArray<EZLanguage> *)preferredTwoLanguages;

- (BOOL)containsEnglishInPreferredTwoLanguages;
- (BOOL)containsChineseInPreferredTwoLanguages;

/// First langauge is simplified Chinese or traditional Chinese.
- (BOOL)isChineseFirstLanguage;
- (BOOL)isEnglishFirstLanguage;

/// Is simplified Chinese or traditional Chinese.
- (BOOL)isChineseLanguage:(EZLanguage)language;

- (BOOL)isSimplifiedChinese:(EZLanguage)language;
- (BOOL)isTraditionalChinese:(EZLanguage)language;
- (BOOL)isEnglishLangauge:(EZLanguage)language;

- (BOOL)containsEnglishPreferredLanguage;
- (BOOL)containsChinesePreferredLanguage;

/// Check if language array only contains simplified Chinese or traditional Chinese two languages.
- (BOOL)onlyContainsChineseLanguages:(NSArray<EZLanguage> *)languages;

#pragma mark -

- (NSArray<EZLanguage> *)allLanguages;

/// Showing language name according user preferred language, Chinese: English -> 英语, English: English -> English.
- (NSString *)showingLanguageName:(EZLanguage)language;

- (NSString *)showingLanguageNameWithFlag:(EZLanguage)language;

/// Get language Chinese name, Chinese -> 中文, English -> 英语.
- (NSString *)languageChineseName:(EZLanguage)language;

/// Get language local name, Chinese -> 中文, English -> English.
- (NSString *)languageLocalName:(EZLanguage)language;

/// Get language flag image, Chinese -> 🇨🇳, English -> 🇬🇧.
- (NSString *)languageFlagEmoji:(EZLanguage)language;

@end

NS_ASSUME_NONNULL_END
