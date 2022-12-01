//
//  EZLanguage.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLanguageTool.h"

NSString *const EZLanguageAuto = @"auto";
NSString *const EZLanguageSimplifiedChinese = @"Chinese-Simplified";
NSString *const EZLanguageTraditionalChinese = @"Chinese-Traditional";
NSString *const EZLanguageEnglish = @"English";
NSString *const EZLanguageJapanese = @"Japanese";
NSString *const EZLanguageKorean = @"Korean";
NSString *const EZLanguageFrench = @"French";
NSString *const EZLanguageSpanish = @"Spanish";
NSString *const EZLanguagePortuguese = @"Portuguese";
NSString *const EZLanguageItalian = @"Italian";
NSString *const EZLanguageGerman = @"German";
NSString *const EZLanguageRussian = @"Russian";
NSString *const EZLanguageArabic = @"Arabic";
NSString *const EZLanguageSwedish = @"Swedish";
NSString *const EZLanguageRomanian = @"Romanian";
NSString *const EZLanguageThai = @"Thai";
NSString *const EZLanguageSlovak = @"Slovak";
NSString *const EZLanguageDutch = @"Dutch";
NSString *const EZLanguageHungarian = @"Hungarian";
NSString *const EZLanguageGreek = @"Greek";
NSString *const EZLanguageDanish = @"Danish";
NSString *const EZLanguageFinnish = @"Finnish";
NSString *const EZLanguagePolish = @"Polish";
NSString *const EZLanguageCzech = @"Czech";
NSString *const EZLanguageTurkish = @"Turkish";
NSString *const EZLanguageLithuanian = @"Lithuanian";
NSString *const EZLanguageLatvian = @"Latvian";
NSString *const EZLanguageUkrainian = @"Ukrainian";
NSString *const EZLanguageBulgarian = @"Bulgarian";
NSString *const EZLanguageIndonesian = @"Indonesian";
NSString *const EZLanguageMalay = @"Malay";
NSString *const EZLanguageSlovenian = @"Slovenian";
NSString *const EZLanguageEstonian = @"Estonian";
NSString *const EZLanguageVietnamese = @"Vietnamese";
NSString *const EZLanguagePersian = @"Persian";
NSString *const EZLanguageHindi = @"Hindi";
NSString *const EZLanguageTelugu = @"Telugu";
NSString *const EZLanguageTamil = @"Tamil";
NSString *const EZLanguageUrdu = @"Urdu";
NSString *const EZLanguageFilipino = @"Filipino";
NSString *const EZLanguageKhmer = @"Khmer";
NSString *const EZLanguageLao = @"Lao";
NSString *const EZLanguageBengali = @"Bengali";
NSString *const EZLanguageNorwegian = @"Norwegian";
NSString *const EZLanguageSerbian = @"Serbian";
NSString *const EZLanguageCroatian = @"Croatian";
NSString *const EZLanguageMongolian = @"Mongolian";
NSString *const EZLanguageHebrew = @"Hebrew";


@implementation EZLanguageTool

// Get target language with source language
+ (EZLanguage)targetLanguageWithSourceLanguage:(EZLanguage)sourceLanguage {
    EZLanguage targetLanguage = EZLanguageAuto;
    if (sourceLanguage == EZLanguageSimplifiedChinese || sourceLanguage == EZLanguageTraditionalChinese) {
        targetLanguage = EZLanguageEnglish;
    } else {
        targetLanguage = EZLanguageSimplifiedChinese;
    }
    return targetLanguage;
}

// Get user system preferred languages
+ (NSArray<NSString *> *)systemPreferredLanguages {
    NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
    NSMutableArray *languages = [NSMutableArray array];
    for (NSString *language in preferredLanguages) {
        [languages addObject:language];
    }

    // The same as abov.
    //    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //    NSArray *userLanguages = [defaults objectForKey:@"AppleLanguages"];

    NSLog(@"languages: %@", languages);

    return languages; // @["zh-Hans-CN", "en-CN"]
}

// Get language Chinese name, such as "简体中文"
+ (NSString *)languageChineseName:(EZLanguage)language {
    static NSDictionary *languageNameDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        languageNameDict = @{
            EZLanguageAuto : @"自动",
            EZLanguageSimplifiedChinese : @"简体中文",
            EZLanguageTraditionalChinese : @"繁体中文",
            EZLanguageEnglish : @"英语",
            EZLanguageJapanese : @"日语",
            EZLanguageKorean : @"韩语",
            EZLanguageFrench : @"法语",
            EZLanguageSpanish : @"西班牙语",
            EZLanguagePortuguese : @"葡萄牙语",
            EZLanguageItalian : @"意大利语",
            EZLanguageGerman : @"德语",
            EZLanguageRussian : @"俄语",
            EZLanguageArabic : @"阿拉伯语",
            EZLanguageSwedish : @"瑞典语",
            EZLanguageRomanian : @"罗马尼亚语",
            EZLanguageThai : @"泰语",
            EZLanguageSlovak : @"斯洛伐克语",
            EZLanguageDutch : @"荷兰语",
            EZLanguageHungarian : @"匈牙利语",
            EZLanguageGreek : @"希腊语",
            EZLanguageDanish : @"丹麦语",
            EZLanguageFinnish : @"芬兰语",
            EZLanguagePolish : @"波兰语",
            EZLanguageCzech : @"捷克语",
            EZLanguageTurkish : @"土耳其语",
            EZLanguageLithuanian : @"立陶宛语",
            EZLanguageLatvian : @"拉脱维亚语",
            EZLanguageUkrainian : @"乌克兰语",
            EZLanguageBulgarian : @"保加利亚语",
            EZLanguageIndonesian : @"印尼语",
            EZLanguageMalay : @"马来语",
            EZLanguageSlovenian : @"斯洛文尼亚语",
            EZLanguageEstonian : @"爱沙尼亚语",
            EZLanguageVietnamese : @"越南语",
            EZLanguagePersian : @"波斯语",
            EZLanguageHindi : @"印地语",
            EZLanguageTelugu : @"泰卢固语",
            EZLanguageTamil : @"泰米尔语",
            EZLanguageUrdu : @"乌尔都语",
            EZLanguageFilipino : @"菲律宾语",
            EZLanguageKhmer : @"高棉语",
            EZLanguageLao : @"老挝语",
            EZLanguageBengali : @"孟加拉语",
            EZLanguageNorwegian : @"挪威语",
            EZLanguageSerbian : @"塞尔维亚语",
            EZLanguageCroatian : @"克罗地亚语",
            EZLanguageMongolian : @"蒙古语",
            EZLanguageHebrew : @"希伯来语",
        };
    });

    return languageNameDict[language];
}

// Get language flag emoji according to language, such as "🇨🇳"
+ (NSString *)languageFlagEmoji:(EZLanguage)language {
    static NSDictionary *languageFlagEmojiDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        languageFlagEmojiDict = @{
            EZLanguageAuto : @"🌐",
            EZLanguageSimplifiedChinese : @"🇨🇳",
            EZLanguageTraditionalChinese : @"🇭🇰",
            EZLanguageEnglish : @"🇬🇧",
            EZLanguageJapanese : @"🇯🇵",
            EZLanguageKorean : @"🇰🇷",
            EZLanguageFrench : @"🇫🇷",
            EZLanguageSpanish : @"🇪🇸",
            EZLanguagePortuguese : @"🇵🇹",
            EZLanguageItalian : @"🇮🇹",
            EZLanguageGerman : @"🇩🇪",
            EZLanguageRussian : @"🇷🇺",
            EZLanguageArabic : @"🇸🇦",
            EZLanguageSwedish : @"🇸🇪",
            EZLanguageRomanian : @"🇷🇴",
            EZLanguageThai : @"🇹🇭",
            EZLanguageSlovak : @"🇸🇰",
            EZLanguageDutch : @"🇳🇱",
            EZLanguageHungarian : @"🇭🇺",
            EZLanguageGreek : @"🇬🇷",
            EZLanguageDanish : @"🇩🇰",
            EZLanguageFinnish : @"🇫🇮",
            EZLanguagePolish : @"🇵🇱",
            EZLanguageCzech : @"🇨🇿",
            EZLanguageTurkish : @"🇹🇷",
            EZLanguageLithuanian : @"🇱🇹",
            EZLanguageLatvian : @"🇱🇻",
            EZLanguageUkrainian : @"🇺🇦",
            EZLanguageBulgarian : @"🇧🇬",
            EZLanguageIndonesian : @"🇮🇩",
            EZLanguageMalay : @"🇲🇾",
            EZLanguageSlovenian : @"🇸🇮",
            EZLanguageEstonian : @"🇪🇪",
            EZLanguageVietnamese : @"🇻🇳",
            EZLanguagePersian : @"🇮🇷",
            EZLanguageHindi : @"🇮🇳",
            EZLanguageTelugu : @"🇮🇳",
            EZLanguageTamil : @"🇮🇳",
            EZLanguageUrdu : @"🇵🇰",
            EZLanguageFilipino : @"🇵🇭",
            EZLanguageKhmer : @"🇰🇭",
            EZLanguageLao : @"🇱🇦",
            EZLanguageBengali : @"🇧🇩",
            EZLanguageNorwegian : @"🇳🇴",
            EZLanguageSerbian : @"🇷🇸",
            EZLanguageCroatian : @"🇭🇷",
            EZLanguageMongolian : @"🇲🇳",
            EZLanguageHebrew : @"🇮🇱",
        };
    });

    return languageFlagEmojiDict[language];
}


@end
