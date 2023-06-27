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
@property (nonatomic, copy, readonly) NSArray<EZLanguage> *userPreferredTwoLanguages;

/// preferredLanguages = userPreferredTwoLanguages + systemPreferredLanguages, remove the same language
@property (nonatomic, copy, readonly) NSArray<EZLanguage> *preferredLanguages;

@property (nonatomic, copy, readonly) EZLanguage userFirstLanguage;
@property (nonatomic, copy, readonly) EZLanguage userSecondLanguage;

@property (nonatomic, copy, readonly) NSArray<EZLanguage> *allLanguages;

/// <EZLanguageEnglish : 🇬🇧 英语>
@property (nonatomic, strong, readonly) MMOrderedDictionary<EZLanguage, NSString *> *allLanguageFlagDict;


- (nullable EZLanguageModel *)languageModelFromLanguage:(EZLanguage)language;

/// Get target language with source language
- (EZLanguage)userTargetLanguageWithSourceLanguage:(EZLanguage)sourceLanguage;

- (BOOL)containsEnglishInPreferredTwoLanguages;
- (BOOL)containsChineseInPreferredTwoLanguages;

/// First langauge is simplified Chinese or traditional Chinese.
- (BOOL)isSystemChineseFirstLanguage;
- (BOOL)isSystemEnglishFirstLanguage;

- (BOOL)isUserChineseFirstLanguage;
- (BOOL)isUserEnglishFirstLanguage;

/// Is simplified Chinese or traditional Chinese.
- (BOOL)isChineseLanguage:(EZLanguage)language;

- (BOOL)isSimplifiedChinese:(EZLanguage)language;
- (BOOL)isTraditionalChinese:(EZLanguage)language;
- (BOOL)isEnglishLangauge:(EZLanguage)language;

/// Check if language array only contains simplified Chinese or traditional Chinese two languages.
- (BOOL)onlyContainsChineseLanguages:(NSArray<EZLanguage> *)languages;

#pragma mark -

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
