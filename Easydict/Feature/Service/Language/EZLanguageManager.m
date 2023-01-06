//
//  EZLanguage.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLanguageManager.h"
#import "EZAppleService.h"

@implementation EZLanguageManager

+ (nullable EZLanguageModel *)languageModelFromLanguage:(EZLanguage)language {
    return [[EZLanguageModel allLanguagesDict] objectForKey:language];
}

// Get language model with locale identifier, such as "zh-CN"
- (nullable EZLanguageModel *)languageModelFromLocaleIdentifier:(NSString *)localeIdentifier {
    for (EZLanguageModel *languageModel in [EZLanguageModel allLanguagesDict].allValues) {
        if ([languageModel.localeIdentifier isEqualToString:localeIdentifier]) {
            return languageModel;
        }
    }
    return nil;
}


// Get target language with source language
+ (EZLanguage)targetLanguageWithSourceLanguage:(EZLanguage)sourceLanguage {
    EZLanguage firstLanguage = [self firstLanguage];
    EZLanguage secondLanguage = [self secondLanguage];
    EZLanguage targetLanguage = firstLanguage;
    if ([sourceLanguage isEqualToString:firstLanguage]) {
        targetLanguage = secondLanguage;
    }
    return targetLanguage;
}

// Get user system preferred languages
+ (NSArray<EZLanguage> *)systemPreferredLanguages {
    // "en-CN", "zh-Hans", "zh-Hans-CN"
    NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
    NSMutableArray *languages = [NSMutableArray array];
    for (NSString *language in preferredLanguages) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:[language componentsSeparatedByString:@"-"]];
        // Remove country code
        [array removeLastObject];
        NSString *languageCode = [array componentsJoinedByString:@"-"];
        // Convert to EZLanguage
        EZAppleService *appleService = [[EZAppleService alloc] init];
        EZLanguage ezLanguage = [appleService appleLanguageEnumFromCode:languageCode];

        [languages addObject:ezLanguage];
    }

    // This method seems to be the same.
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        NSArray *userLanguages = [defaults objectForKey:@"AppleLanguages"];

    //    NSLog(@"languages: %@", languages);

    return languages;
}

+ (NSArray<EZLanguage> *)preferredTwoLanguages {
    NSMutableArray *twoLanguages = [NSMutableArray array];
    NSMutableArray<EZLanguage> *preferredlanguages = [[self systemPreferredLanguages] mutableCopy];

    EZLanguage firstLanguage = [self firstLanguageFromLanguages:preferredlanguages];
    [twoLanguages addObject:firstLanguage];

    // Remove first language
    [preferredlanguages removeObject:firstLanguage];
    
    EZLanguage secondLanguage = [self firstLanguageFromLanguages:preferredlanguages];
    if ([firstLanguage isEqualToString:secondLanguage]) {
        if ([firstLanguage isEqualToString:EZLanguageEnglish]) {
            secondLanguage = EZLanguageSimplifiedChinese;
        } else {
            secondLanguage = EZLanguageEnglish;
        }
    }
    [twoLanguages addObject:secondLanguage];

    return twoLanguages;
}

// Get first language that is not auto, from languages
+ (EZLanguage)firstLanguageFromLanguages:(NSArray<EZLanguage> *)languages {
    for (EZLanguage language in languages) {
        if ([language isEqualToString:EZLanguageAuto]) {
            continue;
        }
        return language;
    }
    return EZLanguageEnglish;
}


+ (BOOL)containsEnglishInPreferredTwoLanguages {
    NSArray<EZLanguage> *languages = [self preferredTwoLanguages];
    return [languages containsObject:EZLanguageEnglish];
}

+ (BOOL)containsChineseInPreferredTwoLanguages {
    NSArray<EZLanguage> *languages = [self preferredTwoLanguages];
    for (EZLanguage language in languages) {
        if ([self isChineseLanguage:language]) {
            return YES;
        }
    }
    return NO;
}


+ (EZLanguage)firstLanguage {
    return [self preferredTwoLanguages][0];
}
+ (EZLanguage)secondLanguage {
    return [self preferredTwoLanguages][1];
}

+ (BOOL)isChineseFirstLanguage {
    EZLanguage firstLanguage = [self firstLanguage];
    return [self isChineseLanguage:firstLanguage];
}

+ (BOOL)isChineseLanguage:(EZLanguage)language {
    if ([language isEqualToString:EZLanguageSimplifiedChinese] || [language isEqualToString:EZLanguageTraditionalChinese]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isEnglishFirstLanguage {
    EZLanguage firstLanguage = [self firstLanguage];
    return [firstLanguage isEqualToString:EZLanguageEnglish];
}


+ (BOOL)containsEnglishPreferredLanguage {
    NSArray<EZLanguage> *languages = [self systemPreferredLanguages];
    for (EZLanguage language in languages) {
        if ([language isEqualToString:EZLanguageEnglish]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)containsChinesePreferredLanguage {
    NSArray<EZLanguage> *languages = [self systemPreferredLanguages];
    for (EZLanguage language in languages) {
        if ([language isEqualToString:EZLanguageEnglish]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark -

+ (NSArray<EZLanguage> *)allLanguages {
    return [[EZLanguageModel allLanguagesDict] sortedKeys];
    ;
}

// Get language flag emoji according to language, such as "🇨🇳"
+ (NSString *)languageFlagEmoji:(EZLanguage)language {
    EZLanguageModel *lang = [[EZLanguageModel allLanguagesDict] objectForKey:language];
    return lang.flagEmoji;
}

// Get language Chinese name, such as "简体中文"
+ (NSString *)languageChineseName:(EZLanguage)language {
    EZLanguageModel *lang = [[EZLanguageModel allLanguagesDict] objectForKey:language];
    return lang.chineseName;
}

/// Showing language name according user first language, Chinese: English -> 英语, English: English -> English.
+ (NSString *)showingLanguageName:(EZLanguage)language {
    NSString *languageName = language;
    if ([self isChineseFirstLanguage]) {
        languageName = [self languageChineseName:language];
    }
    return languageName;
}

+ (NSString *)showingLanguageNameWithFlag:(EZLanguage)language {
    NSString *languageName = [self showingLanguageName:language];
    NSString *flagEmoji = [self languageFlagEmoji:language];
    return [NSString stringWithFormat:@"%@ %@", languageName, flagEmoji];
}

@end
