//
//  EZLanguage.h
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZLanguageManager : NSObject

/// Get target language with source language
+ (EZLanguage)targetLanguageWithSourceLanguage:(EZLanguage)sourceLanguage;

/// User system languages, ["zh-Hans-CN", "en-CN"]
+ (NSArray<EZLanguage> *)systemPreferredLanguages;

+ (NSArray<EZLanguage> *)preferredTwoLanguages;

+ (BOOL)containsEnglishInPreferredTwoLanguages;
+ (BOOL)containsChineseInPreferredTwoLanguages;

/// User first preferred language.
+ (EZLanguage)firstLanguage;
+ (EZLanguage)secondLanguage;

+ (BOOL)isChineseFirstLanguage;
+ (BOOL)isChineseLanguage:(EZLanguage)language;

+ (BOOL)containsEnglishPreferredLanguage;
+ (BOOL)containsChinesePreferredLanguage;


#pragma mark -

+ (NSArray<EZLanguage> *)allLanguages;

/// Showing language name according user preferred language, Chinese: English -> 英语, English: English -> English.
+ (NSString *)showingLanguageName:(EZLanguage)language;

+ (NSString *)showingLanguageNameWithFlag:(EZLanguage)language;

/// Get language Chinese name, Chinese -> 中文, English -> 英语.
+ (NSString *)languageChineseName:(EZLanguage)language;

/// Get language flag image, Chinese -> 🇨🇳, English -> 🇬🇧.
+ (NSString *)languageFlagEmoji:(EZLanguage)language;


@property (nonatomic, copy) NSString *chineseName;
@property (nonatomic, copy) NSString *englishName;
@property (nonatomic, copy) NSString *localName;
@property (nonatomic, copy) NSString *flagEmoji;

@end

NS_ASSUME_NONNULL_END
