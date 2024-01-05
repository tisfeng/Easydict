//
//  EZLanguage.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLanguageManager.h"
#import "EZAppleService.h"
#import "EZConfiguration.h"

@interface EZLanguageManager ()

@property (nonatomic, copy) NSArray<EZLanguage> *systemPreferredLanguages;
@property (nonatomic, copy) NSArray<EZLanguage> *systemPreferredTwoLanguages;
@property (nonatomic, copy) EZLanguage systemFirstLanguage;
@property (nonatomic, copy) EZLanguage systemSecondLanguage;

@property (nonatomic, copy) NSArray<EZLanguage> *userPreferredTwoLanguages;

@property (nonatomic, strong) MMOrderedDictionary<EZLanguage, NSString *> *allLanguageFlagDict;

@end

@implementation EZLanguageManager

static EZLanguageManager *_instance;

+ (instancetype)shared {
    @synchronized(self) {
        if (!_instance) {
            _instance = [[super allocWithZone:NULL] init];
            [_instance setup];
        }
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self shared];
}

+ (void)destroySharedInstance {
    _instance = nil;
}

- (void)setup {
    // Ref: https://stackoverflow.com/a/25011408
    // A workaround of `AppleLanguages` not refresh once inserted object
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLanguages"];
    NSArray *showingLanguages = [EZLanguageManager.shared allLanguages];
    self.allLanguageFlagDict = [[MMOrderedDictionary alloc] init];
    for (EZLanguage language in showingLanguages) {
        if (![language isEqualToString:EZLanguageAuto]) {
            NSString *languageNameWithFlag = [EZLanguageManager.shared showingLanguageNameWithFlag:language];
            [self.allLanguageFlagDict setObject:languageNameWithFlag forKey:language];
        }
    }
}

- (NSArray<EZLanguage> *)systemPreferredLanguages {
    if (!_systemPreferredLanguages) {
        /**
         "en-CN", "zh-Hans", "zh-Hans-CN"
         ???: Why has changed to [ "zh-CN", "zh-Hans-CN", "en-CN" ]
         
         [NSLocale preferredLanguages] is device languages, and it is read only.
         [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] is the same with [NSLocale preferredLanguages] generally, but it can be modified.
         
         Changing the system language does not seem to take effect immediately and may require a reboot of the computer.
         
         Ref https://stackoverflow.com/a/4221416/8378840
         !!!: For Canadian English, AppleLanguages returns "en_CA", while [NSLocale preferredLanguages] returns "en-CA"
         */
        
        NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
        //        NSArray<NSString *> *preferredLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
        
        // Chinese (Hong kong) --> zh-HK
        // Chinese, Traditional --> zh-Hant
        MMLogInfo(@"AppleLanguages: %@", preferredLanguages);
        
        NSMutableArray *languages = [NSMutableArray array];
        for (NSString *language in preferredLanguages) {
            // "zh-Hans-CN"
            NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:language];
            NSString *languageCode = [languageDic objectForKey:NSLocaleLanguageCode]; // zh
            NSString *scriptCode = [languageDic objectForKey:NSLocaleScriptCode];     // Hans
            //  NSString *countryCode = [languageDic objectForKey:NSLocaleCountryCode];   // CN
            
            NSString *languageScriptCode = languageCode;
            if (scriptCode) {
                // Only some special languages have script code, such as zh-Hans, zh-Hant.
                languageScriptCode = [NSString stringWithFormat:@"%@-%@", languageCode, scriptCode];
            }
            
            // Convert to EZLanguage
            EZLanguage ezLanguage = [EZAppleService.shared languageEnumFromAppleLanguage:languageScriptCode];
            
            // Handle "zh-CN"
            if ([languageScriptCode hasPrefix:@"zh"] && [ezLanguage isEqualToString:EZLanguageAuto]) {
                ezLanguage = EZLanguageSimplifiedChinese;
            }
            
            if (![ezLanguage isEqualToString:EZLanguageAuto] && ![languages containsObject:ezLanguage]) {
                [languages addObject:ezLanguage];
            }
        }
        
        _systemPreferredLanguages = languages;
        
        MMLogInfo(@"system preferred languages: %@", languages);
    }
    
    return _systemPreferredLanguages;
}

- (NSArray<EZLanguage> *)systemPreferredTwoLanguages {
    if (!_systemPreferredTwoLanguages) {
        NSMutableArray *twoLanguages = [NSMutableArray array];
        NSMutableArray<EZLanguage> *preferredlanguages = [self.systemPreferredLanguages mutableCopy];
        
        EZLanguage firstLanguage = [self firstLanguageFromLanguages:preferredlanguages];
        [twoLanguages addObject:firstLanguage];
        
        // Remove first language
        [preferredlanguages removeObject:firstLanguage];
        
        EZLanguage secondLanguage = [self firstLanguageFromLanguages:preferredlanguages];
        if ([firstLanguage isEqualToString:secondLanguage]) {
            secondLanguage = [self autoTargetLanguageWithSourceLanguage:firstLanguage];
        }
        [twoLanguages addObject:secondLanguage];
        
        _systemPreferredTwoLanguages = twoLanguages;
    }
    return _systemPreferredTwoLanguages;
}

/// preferredLanguages = userPreferredTwoLanguages + systemPreferredLanguages, remove the same language
- (NSArray<EZLanguage> *)preferredLanguages {
    NSMutableArray *preferredLanguages = [NSMutableArray array];
    [preferredLanguages addObjectsFromArray:self.userPreferredTwoLanguages];
    [preferredLanguages addObjectsFromArray:self.systemPreferredLanguages];
    
    NSMutableArray *languages = [NSMutableArray array];
    for (EZLanguage language in preferredLanguages) {
        if (![languages containsObject:language]) {
            [languages addObject:language];
        }
    }
    return languages;
}


- (EZLanguage)systemFirstLanguage {
    EZLanguage firstLanguage = [self.systemPreferredTwoLanguages firstObject];
    return firstLanguage;
}
- (EZLanguage)systemSecondLanguage {
    EZLanguage secondLanguage = [self.systemPreferredTwoLanguages lastObject];
    return secondLanguage;
}


- (NSArray<EZLanguage> *)userPreferredTwoLanguages {
    NSArray *twoLanguages = @[ self.userFirstLanguage, self.userSecondLanguage ];
    return twoLanguages;
}

- (EZLanguage)userFirstLanguage {
    EZLanguage firstLanguage = EZConfiguration.shared.firstLanguage;
    if (!firstLanguage) {
        firstLanguage = [self systemPreferredTwoLanguages][0];
    }
    return firstLanguage;
}

- (EZLanguage)userSecondLanguage {
    EZLanguage secondLanguage = EZConfiguration.shared.secondLanguage;
    if (!secondLanguage) {
        secondLanguage = [self systemPreferredTwoLanguages][1];
    }
    return secondLanguage;
}

- (MMOrderedDictionary<EZLanguage, NSString *> *)allLanguageFlagDict {
    if (!_allLanguageFlagDict) {
        MMOrderedDictionary *languageDict = [[MMOrderedDictionary alloc] init];
        for (EZLanguage language in self.allLanguages) {
            if (![language isEqualToString:EZLanguageAuto]) {
                NSString *languageNameWithFlag = [self showingLanguageNameWithFlag:language];
                [languageDict setObject:languageNameWithFlag forKey:language];
            }
        }
        _allLanguageFlagDict = languageDict;
    }
    return _allLanguageFlagDict;
}


- (nullable EZLanguageModel *)languageModelFromLanguage:(EZLanguage)language {
    return [[EZLanguageModel allLanguagesDict] objectForKey:language];
}

// Get target language with source language
- (EZLanguage)userTargetLanguageWithSourceLanguage:(EZLanguage)sourceLanguage {
    EZLanguage firstLanguage = [self userFirstLanguage];
    EZLanguage secondLanguage = [self userSecondLanguage];
    EZLanguage targetLanguage = firstLanguage;
    if ([sourceLanguage isEqualToString:firstLanguage]) {
        targetLanguage = secondLanguage;
    }
    
    if ([targetLanguage isEqualToString:sourceLanguage]) {
        targetLanguage = [self autoTargetLanguageWithSourceLanguage:sourceLanguage];
    }
    
    return targetLanguage;
}

/// If sourceLanguage is English, return Chinese, else return English.
- (EZLanguage)autoTargetLanguageWithSourceLanguage:(EZLanguage)sourceLanguage {
    EZLanguage targetLanguage = EZLanguageEnglish;
    if ([sourceLanguage isEqualToString:EZLanguageEnglish]) {
        targetLanguage = EZLanguageSimplifiedChinese;
    }
    return targetLanguage;
}

// Get first language that is not auto, from languages
- (EZLanguage)firstLanguageFromLanguages:(NSArray<EZLanguage> *)languages {
    for (EZLanguage language in languages) {
        if (![language isEqualToString:EZLanguageAuto]) {
            return language;
        }
    }
    return EZLanguageEnglish;
}


- (BOOL)containsEnglishInPreferredTwoLanguages {
    NSArray<EZLanguage> *languages = [self userPreferredTwoLanguages];
    return [languages containsObject:EZLanguageEnglish];
}

- (BOOL)containsChineseInPreferredTwoLanguages {
    NSArray<EZLanguage> *languages = [self userPreferredTwoLanguages];
    for (EZLanguage language in languages) {
        if ([self isChineseLanguage:language]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isSystemEnglishFirstLanguage {
    return [self.systemFirstLanguage isEqualToString:EZLanguageEnglish];
}
- (BOOL)isSystemChineseFirstLanguage {
    return [self isChineseLanguage:self.systemFirstLanguage];
}

- (BOOL)isUserChineseFirstLanguage {
    return [self isChineseLanguage:self.userFirstLanguage];
}
- (BOOL)isUserEnglishFirstLanguage {
    return [self.userFirstLanguage isEqualToString:EZLanguageEnglish];
}

/// Is simplified, traditional or classical Chinese.
- (BOOL)isChineseLanguage:(EZLanguage)language {
    if ([language isEqualToString:EZLanguageSimplifiedChinese] ||
        [language isEqualToString:EZLanguageTraditionalChinese] ||
        [language isEqualToString:EZLanguageClassicalChinese]) {
        return YES;
    }
    return NO;
}

- (BOOL)isSimplifiedChinese:(EZLanguage)language {
    return [language isEqualToString:EZLanguageSimplifiedChinese];
}

- (BOOL)isTraditionalChinese:(EZLanguage)language {
    return [language isEqualToString:EZLanguageTraditionalChinese];
}

- (BOOL)isEnglishLangauge:(EZLanguage)language {
    return [language isEqualToString:EZLanguageEnglish];
}

/// Check if language array only contains simplified Chinese or traditional Chinese two languages.
- (BOOL)onlyContainsChineseLanguages:(NSArray<EZLanguage> *)languages {
    for (EZLanguage language in languages) {
        if (!([self isSimplifiedChinese:language] || [self isTraditionalChinese:language])) {
            return NO;
        }
    }
    return YES;
}

/// Languages that don't need extra space for words, generally non-Engglish alphabet languages.
- (BOOL)isLanguageWordsNeedSpace:(EZLanguage)language {
    NSArray *languages = @[
        EZLanguageSimplifiedChinese,
        EZLanguageTraditionalChinese,
        EZLanguageJapanese,
        EZLanguageKorean,
    ];
    return ![languages containsObject:language];
}

- (BOOL)isShortWordLength:(NSString *)word language:(EZLanguage)language {
    BOOL isShortWordLength;
    NSInteger wordLength = word.length;
    BOOL isNeedSpaceLanguage = [EZLanguageManager.shared isLanguageWordsNeedSpace:language];
    
    if (isNeedSpaceLanguage) {
        isShortWordLength = wordLength <= EZEnglishWordMaxLength;
    } else {
        isShortWordLength = wordLength <= 7;
    }
    isShortWordLength = wordLength && isShortWordLength;
    
    return isShortWordLength;
}

#pragma mark -

- (NSArray<EZLanguage> *)allLanguages {
    return [[EZLanguageModel allLanguagesDict] sortedKeys];
}

// Get language flag emoji according to language, such as "🇨🇳"
- (NSString *)languageFlagEmoji:(EZLanguage)language {
    EZLanguageModel *lang = [[EZLanguageModel allLanguagesDict] objectForKey:language];
    return lang.flagEmoji;
}

// Get language Chinese name, such as "简体中文"
- (NSString *)languageChineseName:(EZLanguage)language {
    EZLanguageModel *lang = [[EZLanguageModel allLanguagesDict] objectForKey:language];
    return lang.chineseName;
}

/// Get language local name, Chinese -> 中文, English -> English.
- (NSString *)languageLocalName:(EZLanguage)language {
    EZLanguageModel *lang = [[EZLanguageModel allLanguagesDict] objectForKey:language];
    return lang.localName;
}

/// Showing language name according user first language, Chinese: English -> 英语, English: English -> English.
- (NSString *)showingLanguageName:(EZLanguage)language {
    NSString *languageName = language ?: EZLanguageAuto;
    if ([self isSystemChineseFirstLanguage]) {
        languageName = [self languageChineseName:language];
    } else {
        if ([language isEqualToString:EZLanguageAuto]) {
            languageName = @"Auto"; // auto --> Auto
        }
    }
    return languageName;
}

- (NSString *)showingLanguageNameWithFlag:(EZLanguage)language {
    NSString *languageName = [self showingLanguageName:language];
    NSString *flagEmoji = [self languageFlagEmoji:language];
    return [NSString stringWithFormat:@"%@ %@", flagEmoji, languageName];
}

@end
