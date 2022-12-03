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
    // ["zh-Hans-CN", "en-CN"]
    NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
    NSMutableArray *languages = [NSMutableArray array];
    for (NSString *language in preferredLanguages) {
        // "zh-Hans-CN" -> "zh-Hans"
        NSMutableArray *array = [NSMutableArray arrayWithArray:[language componentsSeparatedByString:@"-"]];
        // Remove country code
        [array removeLastObject];
        NSString *languageCode = [array componentsJoinedByString:@"-"];
        // Convert to EZLanguage
        EZAppleService *appleService = [[EZAppleService alloc] init];
        EZLanguage ezLanguage = [appleService languageEnumFromString:languageCode];

        [languages addObject:ezLanguage];
    }

    // This method seems to be the same.
    //    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //    NSArray *userLanguages = [defaults objectForKey:@"AppleLanguages"];

    //    NSLog(@"languages: %@", languages);

    return languages;
}

+ (NSArray<EZLanguage> *)preferredTwoLanguages {
    NSMutableArray *twoLanguages = [NSMutableArray array];
    NSArray<EZLanguage> *languages = [self systemPreferredLanguages];

    EZLanguage firstLanguage = languages.firstObject;
    [twoLanguages addObject:firstLanguage];

    if (languages.count > 1) {
        [twoLanguages addObject:languages[1]];
    } else {
        EZLanguage secondLanguage = EZLanguageEnglish;
        if ([firstLanguage isEqualToString:EZLanguageEnglish]) {
            secondLanguage = EZLanguageSimplifiedChinese;
        }
        [twoLanguages addObject:secondLanguage];
    }

    return twoLanguages;
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
    if (language == EZLanguageSimplifiedChinese || language == EZLanguageTraditionalChinese) {
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
        if (language == EZLanguageEnglish) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)containsChinesePreferredLanguage {
    NSArray<EZLanguage> *languages = [self systemPreferredLanguages];
    for (EZLanguage language in languages) {
        if (language == EZLanguageEnglish) {
            return YES;
        }
    }
    return NO;
}


#pragma mark -

+ (NSArray<EZLanguage> *)allLanguages {
    return [[EZLanguageClass allLanguagesDict] sortedKeys];;
}

// Get language flag emoji according to language, such as "🇨🇳"
+ (NSString *)languageFlagEmoji:(EZLanguage)language {
    EZLanguageClass *lang = [[EZLanguageClass allLanguagesDict] objectForKey:language];
    return lang.flagEmoji;
}

// Get language Chinese name, such as "简体中文"
+ (NSString *)languageChineseName:(EZLanguage)language {
    EZLanguageClass *lang = [[EZLanguageClass allLanguagesDict] objectForKey:language];
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
