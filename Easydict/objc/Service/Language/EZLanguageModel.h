//
//  EZLanguageConst.h
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMOrderedDictionary.h"

NS_ASSUME_NONNULL_BEGIN

// Refer Apple NLLanguage.
typedef NSString *EZLanguage NS_STRING_ENUM NS_SWIFT_NAME(Language);

// 目前总计支持 49 种语言：简体中文，繁体中文，文言文，英语，日语，韩语，法语，西班牙语，葡萄牙语，意大利语，德语，俄语，阿拉伯语，瑞典语，罗马尼亚语，泰语，斯洛伐克语，荷兰语，匈牙利语，希腊语，丹麦语，芬兰语，波兰语，捷克语，土耳其语，立陶宛语，拉脱维亚语，乌克兰语，保加利亚语，印尼语，马来语，斯洛文尼亚语，爱沙尼亚语，越南语，波斯语，印地语，泰卢固语，泰米尔语，乌尔都语，菲律宾语，高棉语，老挝语，孟加拉语，缅甸语，挪威语，塞尔维亚语，克罗地亚语，蒙古语，希伯来语。

// Currently supports 49 languages: Simplified Chinese, Traditional Chinese, Classical Chinese, English, Japanese, Korean, French, Spanish, Portuguese, Italian, German, Russian, Arabic, Swedish, Romanian, Thai, Slovak, Dutch, Hungarian, Greek, Danish, Finnish, Polish, Czech, Turkish, Lithuanian, Latvian, Ukrainian, Bulgarian, Indonesian, Malay, Slovenian, Estonian, Vietnamese, Persian, Hindi, Telugu, Tamil, Urdu, Filipino, Khmer, Lao, Bengali, Burmese, Norwegian, Serbian, Croatian, Mongolian, Hebrew.

FOUNDATION_EXPORT EZLanguage const EZLanguageAuto;
FOUNDATION_EXPORT EZLanguage const EZLanguageSimplifiedChinese;
FOUNDATION_EXPORT EZLanguage const EZLanguageTraditionalChinese;
FOUNDATION_EXPORT EZLanguage const EZLanguageClassicalChinese;
FOUNDATION_EXPORT EZLanguage const EZLanguageEnglish;
FOUNDATION_EXPORT EZLanguage const EZLanguageJapanese;
FOUNDATION_EXPORT EZLanguage const EZLanguageKorean;
FOUNDATION_EXPORT EZLanguage const EZLanguageFrench;
FOUNDATION_EXPORT EZLanguage const EZLanguageSpanish;
FOUNDATION_EXPORT EZLanguage const EZLanguagePortuguese;
FOUNDATION_EXPORT EZLanguage const EZLanguageItalian;
FOUNDATION_EXPORT EZLanguage const EZLanguageGerman;
FOUNDATION_EXPORT EZLanguage const EZLanguageRussian;
FOUNDATION_EXPORT EZLanguage const EZLanguageArabic;
FOUNDATION_EXPORT EZLanguage const EZLanguageSwedish;
FOUNDATION_EXPORT EZLanguage const EZLanguageRomanian;
FOUNDATION_EXPORT EZLanguage const EZLanguageThai;
FOUNDATION_EXPORT EZLanguage const EZLanguageSlovak;
FOUNDATION_EXPORT EZLanguage const EZLanguageDutch;
FOUNDATION_EXPORT EZLanguage const EZLanguageHungarian;
FOUNDATION_EXPORT EZLanguage const EZLanguageGreek;
FOUNDATION_EXPORT EZLanguage const EZLanguageDanish;
FOUNDATION_EXPORT EZLanguage const EZLanguageFinnish;
FOUNDATION_EXPORT EZLanguage const EZLanguagePolish;
FOUNDATION_EXPORT EZLanguage const EZLanguageCzech;
FOUNDATION_EXPORT EZLanguage const EZLanguageTurkish;
FOUNDATION_EXPORT EZLanguage const EZLanguageLithuanian;
FOUNDATION_EXPORT EZLanguage const EZLanguageLatvian;
FOUNDATION_EXPORT EZLanguage const EZLanguageUkrainian;
FOUNDATION_EXPORT EZLanguage const EZLanguageBulgarian;
FOUNDATION_EXPORT EZLanguage const EZLanguageIndonesian;
FOUNDATION_EXPORT EZLanguage const EZLanguageMalay;
FOUNDATION_EXPORT EZLanguage const EZLanguageSlovenian;
FOUNDATION_EXPORT EZLanguage const EZLanguageEstonian;
FOUNDATION_EXPORT EZLanguage const EZLanguageVietnamese;
FOUNDATION_EXPORT EZLanguage const EZLanguagePersian;
FOUNDATION_EXPORT EZLanguage const EZLanguageHindi;
FOUNDATION_EXPORT EZLanguage const EZLanguageTelugu;
FOUNDATION_EXPORT EZLanguage const EZLanguageTamil;
FOUNDATION_EXPORT EZLanguage const EZLanguageUrdu;
FOUNDATION_EXPORT EZLanguage const EZLanguageFilipino;
FOUNDATION_EXPORT EZLanguage const EZLanguageKhmer;
FOUNDATION_EXPORT EZLanguage const EZLanguageLao;
FOUNDATION_EXPORT EZLanguage const EZLanguageBengali;
FOUNDATION_EXPORT EZLanguage const EZLanguageBurmese;
FOUNDATION_EXPORT EZLanguage const EZLanguageNorwegian;
FOUNDATION_EXPORT EZLanguage const EZLanguageSerbian;
FOUNDATION_EXPORT EZLanguage const EZLanguageCroatian;
FOUNDATION_EXPORT EZLanguage const EZLanguageMongolian;
FOUNDATION_EXPORT EZLanguage const EZLanguageHebrew;

FOUNDATION_EXPORT EZLanguage const EZLanguageUnsupported;

@interface EZLanguageModel : NSObject

@property (nonatomic, copy) NSString *chineseName;
@property (nonatomic, copy) EZLanguage englishName;
@property (nonatomic, copy) NSString *localName;
@property (nonatomic, copy) NSString *flagEmoji;
@property (nonatomic, copy) NSString *voiceName; // Chinese: Tingting, English: Samantha
@property (nonatomic, copy) NSString *localeIdentifier; //  ISO 639-1 and ISO 3166-1, such as en_US, zh_CN


+ (MMOrderedDictionary<EZLanguage, EZLanguageModel *> *)allLanguagesDict;

@end

NS_ASSUME_NONNULL_END
