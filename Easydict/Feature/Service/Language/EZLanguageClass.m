//
//  EZLanguageConst.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLanguageClass.h"

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

@implementation EZLanguageClass

// 目前总计支持 48 种语言：简体中文，繁体中文，英语，日语，韩语，法语，西班牙语，葡萄牙语，意大利语，德语，俄语，阿拉伯语，瑞典语，罗马尼亚语，泰语，斯洛伐克语，荷兰语，匈牙利语，希腊语，丹麦语，芬兰语，波兰语，捷克语，土耳其语，立陶宛语，拉脱维亚语，乌克兰语，保加利亚语，印尼语，马来语，斯洛文尼亚语，爱沙尼亚语，越南语，波斯语，印地语，泰卢固语，泰米尔语，乌尔都语，菲律宾语，高棉语，老挝语，孟加拉语，缅甸语，挪威语，塞尔维亚语，克罗地亚语，蒙古语，希伯来语。
+ (MMOrderedDictionary<EZLanguage, EZLanguageClass *> *)allLanguagesDict {
    static MMOrderedDictionary *allLanguages;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allLanguages = [[MMOrderedDictionary alloc] init];

        EZLanguageClass *autoLang = [[EZLanguageClass alloc] init];
        autoLang.chineseName = @"自动检测";
        autoLang.englishName = EZLanguageAuto;
        autoLang.localName = @"auto";
        autoLang.flagEmoji = @"🌐";
        [allLanguages setObject:autoLang forKey:EZLanguageAuto];

        EZLanguageClass *chineseSimplifiedLang = [[EZLanguageClass alloc] init];
        chineseSimplifiedLang.chineseName = @"简体中文";
        chineseSimplifiedLang.englishName = EZLanguageSimplifiedChinese;
        chineseSimplifiedLang.localName = @"简体中文";
        chineseSimplifiedLang.flagEmoji = @"🇨🇳";
        [allLanguages setObject:chineseSimplifiedLang forKey:EZLanguageSimplifiedChinese];

        EZLanguageClass *chineseTraditionalLang = [[EZLanguageClass alloc] init];
        chineseTraditionalLang.chineseName = @"繁体中文";
        chineseTraditionalLang.englishName = EZLanguageTraditionalChinese;
        chineseTraditionalLang.localName = @"繁體中文";
        chineseTraditionalLang.flagEmoji = @"🇭🇰";
        [allLanguages setObject:chineseTraditionalLang forKey:EZLanguageTraditionalChinese];

        EZLanguageClass *englishLang = [[EZLanguageClass alloc] init];
        englishLang.chineseName = @"英语";
        englishLang.englishName = EZLanguageEnglish;
        englishLang.localName = @"English";
        englishLang.flagEmoji = @"🇬🇧";
        [allLanguages setObject:englishLang forKey:EZLanguageEnglish];

        EZLanguageClass *japaneseLang = [[EZLanguageClass alloc] init];
        japaneseLang.chineseName = @"日语";
        japaneseLang.englishName = EZLanguageJapanese;
        japaneseLang.localName = @"日本語";
        japaneseLang.flagEmoji = @"🇯🇵";
        [allLanguages setObject:japaneseLang forKey:EZLanguageJapanese];

        EZLanguageClass *koreanLang = [[EZLanguageClass alloc] init];
        koreanLang.chineseName = @"韩语";
        koreanLang.englishName = EZLanguageKorean;
        koreanLang.localName = @"한국어";
        koreanLang.flagEmoji = @"🇰🇷";
        [allLanguages setObject:koreanLang forKey:EZLanguageKorean];

        EZLanguageClass *frenchLang = [[EZLanguageClass alloc] init];
        frenchLang.chineseName = @"法语";
        frenchLang.englishName = EZLanguageFrench;
        frenchLang.localName = @"Français";
        frenchLang.flagEmoji = @"🇫🇷";
        [allLanguages setObject:frenchLang forKey:EZLanguageFrench];

        EZLanguageClass *spanishLang = [[EZLanguageClass alloc] init];
        spanishLang.chineseName = @"西班牙语";
        spanishLang.englishName = EZLanguageSpanish;
        spanishLang.localName = @"Español";
        spanishLang.flagEmoji = @"🇪🇸";
        [allLanguages setObject:spanishLang forKey:EZLanguageSpanish];

        EZLanguageClass *portuguese = [[EZLanguageClass alloc] init];
        portuguese.chineseName = @"葡萄牙语";
        portuguese.englishName = EZLanguagePortuguese;
        portuguese.localName = @"Português";
        portuguese.flagEmoji = @"🇵🇹";
        [allLanguages setObject:portuguese forKey:EZLanguagePortuguese];

        EZLanguageClass *italianLang = [[EZLanguageClass alloc] init];
        italianLang.chineseName = @"意大利语";
        italianLang.englishName = EZLanguageItalian;
        italianLang.localName = @"Italiano";
        italianLang.flagEmoji = @"🇮🇹";
        [allLanguages setObject:italianLang forKey:EZLanguageItalian];

        EZLanguageClass *germanLang = [[EZLanguageClass alloc] init];
        germanLang.chineseName = @"德语";
        germanLang.englishName = EZLanguageGerman;
        germanLang.localName = @"Deutsch";
        germanLang.flagEmoji = @"🇩🇪";
        [allLanguages setObject:germanLang forKey:EZLanguageGerman];

        EZLanguageClass *russianLang = [[EZLanguageClass alloc] init];
        russianLang.chineseName = @"俄语";
        russianLang.englishName = EZLanguageRussian;
        russianLang.localName = @"Русский";
        russianLang.flagEmoji = @"🇷🇺";
        [allLanguages setObject:russianLang forKey:EZLanguageRussian];

        EZLanguageClass *arabicLang = [[EZLanguageClass alloc] init];
        arabicLang.chineseName = @"阿拉伯语";
        arabicLang.englishName = EZLanguageArabic;
        arabicLang.localName = @"العربية";
        arabicLang.flagEmoji = @"🇸🇦";
        [allLanguages setObject:arabicLang forKey:EZLanguageArabic];

        EZLanguageClass *swedishLang = [[EZLanguageClass alloc] init];
        swedishLang.chineseName = @"瑞典语";
        swedishLang.englishName = EZLanguageSwedish;
        swedishLang.localName = @"Svenska";
        swedishLang.flagEmoji = @"🇸🇪";
        [allLanguages setObject:swedishLang forKey:EZLanguageSwedish];

        EZLanguageClass *romanianLang = [[EZLanguageClass alloc] init];
        romanianLang.chineseName = @"罗马尼亚语";
        romanianLang.englishName = EZLanguageRomanian;
        romanianLang.localName = @"Română";
        romanianLang.flagEmoji = @"🇷🇴";
        [allLanguages setObject:romanianLang forKey:EZLanguageRomanian];

        EZLanguageClass *thaLang = [[EZLanguageClass alloc] init];
        thaLang.chineseName = @"泰语";
        thaLang.englishName = EZLanguageThai;
        thaLang.localName = @"ไทย";
        thaLang.flagEmoji = @"🇹🇭";
        [allLanguages setObject:thaLang forKey:EZLanguageThai];

        EZLanguageClass *slovakLang = [[EZLanguageClass alloc] init];
        slovakLang.chineseName = @"斯洛伐克语";
        slovakLang.englishName = EZLanguageSlovak;
        slovakLang.localName = @"Slovenčina";
        slovakLang.flagEmoji = @"🇸🇰";
        [allLanguages setObject:slovakLang forKey:EZLanguageSlovak];

        EZLanguageClass *dutchLang = [[EZLanguageClass alloc] init];
        dutchLang.chineseName = @"荷兰语";
        dutchLang.englishName = EZLanguageDutch;
        dutchLang.localName = @"Nederlands";
        dutchLang.flagEmoji = @"🇳🇱";
        [allLanguages setObject:dutchLang forKey:EZLanguageDutch];

        EZLanguageClass *hungarianLang = [[EZLanguageClass alloc] init];
        hungarianLang.chineseName = @"匈牙利语";
        hungarianLang.englishName = EZLanguageHungarian;
        hungarianLang.localName = @"Magyar";
        hungarianLang.flagEmoji = @"🇭🇺";
        [allLanguages setObject:hungarianLang forKey:EZLanguageHungarian];

        EZLanguageClass *greekLang = [[EZLanguageClass alloc] init];
        greekLang.chineseName = @"希腊语";
        greekLang.englishName = EZLanguageGreek;
        greekLang.localName = @"Ελληνικά";
        greekLang.flagEmoji = @"🇬🇷";
        [allLanguages setObject:greekLang forKey:EZLanguageGreek];

        EZLanguageClass *danishLang = [[EZLanguageClass alloc] init];
        danishLang.chineseName = @"丹麦语";
        danishLang.englishName = EZLanguageDanish;
        danishLang.localName = @"Dansk";
        danishLang.flagEmoji = @"🇩🇰";
        [allLanguages setObject:danishLang forKey:EZLanguageDanish];

        EZLanguageClass *finnishLang = [[EZLanguageClass alloc] init];
        finnishLang.chineseName = @"芬兰语";
        finnishLang.englishName = EZLanguageFinnish;
        finnishLang.localName = @"Suomi";
        finnishLang.flagEmoji = @"🇫🇮";
        [allLanguages setObject:finnishLang forKey:EZLanguageFinnish];

        EZLanguageClass *polishLang = [[EZLanguageClass alloc] init];
        polishLang.chineseName = @"波兰语";
        polishLang.englishName = EZLanguagePolish;
        polishLang.localName = @"Polski";
        polishLang.flagEmoji = @"🇵🇱";
        [allLanguages setObject:polishLang forKey:EZLanguagePolish];

        EZLanguageClass *czechLang = [[EZLanguageClass alloc] init];
        czechLang.chineseName = @"捷克语";
        czechLang.englishName = EZLanguageCzech;
        czechLang.localName = @"Čeština";
        czechLang.flagEmoji = @"🇨🇿";
        [allLanguages setObject:czechLang forKey:EZLanguageCzech];

        EZLanguageClass *turkishLang = [[EZLanguageClass alloc] init];
        turkishLang.chineseName = @"土耳其语";
        turkishLang.englishName = EZLanguageTurkish;
        turkishLang.localName = @"Türkçe";
        turkishLang.flagEmoji = @"🇹🇷";
        [allLanguages setObject:turkishLang forKey:EZLanguageTurkish];

        EZLanguageClass *lituanianLang = [[EZLanguageClass alloc] init];
        lituanianLang.chineseName = @"立陶宛语";
        lituanianLang.englishName = EZLanguageLithuanian;
        lituanianLang.localName = @"Lietuvių";
        lituanianLang.flagEmoji = @"🇱🇹";
        [allLanguages setObject:lituanianLang forKey:EZLanguageLithuanian];

        EZLanguageClass *latvianLang = [[EZLanguageClass alloc] init];
        latvianLang.chineseName = @"拉脱维亚语";
        latvianLang.englishName = EZLanguageLatvian;
        latvianLang.localName = @"Latviešu";
        latvianLang.flagEmoji = @"🇱🇻";
        [allLanguages setObject:latvianLang forKey:EZLanguageLatvian];

        EZLanguageClass *ukrainianLang = [[EZLanguageClass alloc] init];
        ukrainianLang.chineseName = @"乌克兰语";
        ukrainianLang.englishName = EZLanguageUkrainian;
        ukrainianLang.localName = @"Українська";
        ukrainianLang.flagEmoji = @"🇺🇦";
        [allLanguages setObject:ukrainianLang forKey:EZLanguageUkrainian];

        EZLanguageClass *bulgarianLang = [[EZLanguageClass alloc] init];
        bulgarianLang.chineseName = @"保加利亚语";
        bulgarianLang.englishName = EZLanguageBulgarian;
        bulgarianLang.localName = @"Български";
        bulgarianLang.flagEmoji = @"🇧🇬";
        [allLanguages setObject:bulgarianLang forKey:EZLanguageBulgarian];

        EZLanguageClass *indonesianLang = [[EZLanguageClass alloc] init];
        indonesianLang.chineseName = @"印尼语";
        indonesianLang.englishName = EZLanguageIndonesian;
        indonesianLang.localName = @"Bahasa Indonesia";
        indonesianLang.flagEmoji = @"🇮🇩";
        [allLanguages setObject:indonesianLang forKey:EZLanguageIndonesian];

        EZLanguageClass *malayLang = [[EZLanguageClass alloc] init];
        malayLang.chineseName = @"马来语";
        malayLang.englishName = EZLanguageMalay;
        malayLang.localName = @"Bahasa Melayu";
        malayLang.flagEmoji = @"🇲🇾";
        [allLanguages setObject:malayLang forKey:EZLanguageMalay];

        EZLanguageClass *slovenian = [[EZLanguageClass alloc] init];
        slovenian.chineseName = @"斯洛文尼亚语";
        slovenian.englishName = EZLanguageSlovenian;
        slovenian.localName = @"Slovenščina";
        slovenian.flagEmoji = @"🇸🇮";
        [allLanguages setObject:slovenian forKey:EZLanguageSlovenian];

        EZLanguageClass *estonianLang = [[EZLanguageClass alloc] init];
        estonianLang.chineseName = @"爱沙尼亚语";
        estonianLang.englishName = EZLanguageEstonian;
        estonianLang.localName = @"Eesti";
        estonianLang.flagEmoji = @"🇪🇪";
        [allLanguages setObject:estonianLang forKey:EZLanguageEstonian];

        EZLanguageClass *vietnameseLang = [[EZLanguageClass alloc] init];
        vietnameseLang.chineseName = @"越南语";
        vietnameseLang.englishName = EZLanguageVietnamese;
        vietnameseLang.localName = @"Tiếng Việt";
        vietnameseLang.flagEmoji = @"🇻🇳";
        [allLanguages setObject:vietnameseLang forKey:EZLanguageVietnamese];

        EZLanguageClass *persianLang = [[EZLanguageClass alloc] init];
        persianLang.chineseName = @"波斯语";
        persianLang.englishName = EZLanguagePersian;
        persianLang.localName = @"فارسی";
        persianLang.flagEmoji = @"🇮🇷";
        [allLanguages setObject:persianLang forKey:EZLanguagePersian];

        EZLanguageClass *hindiLang = [[EZLanguageClass alloc] init];
        hindiLang.chineseName = @"印地语";
        hindiLang.englishName = EZLanguageHindi;
        hindiLang.localName = @"हिन्दी";
        hindiLang.flagEmoji = @"🇮🇳";
        [allLanguages setObject:hindiLang forKey:EZLanguageHindi];

        EZLanguageClass *teluguLang = [[EZLanguageClass alloc] init];
        teluguLang.chineseName = @"泰卢固语";
        teluguLang.englishName = EZLanguageTelugu;
        teluguLang.localName = @"తెలుగు";
        teluguLang.flagEmoji = @"🇮🇳";
        [allLanguages setObject:teluguLang forKey:EZLanguageTelugu];

        EZLanguageClass *tamilLang = [[EZLanguageClass alloc] init];
        tamilLang.chineseName = @"泰米尔语";
        tamilLang.englishName = EZLanguageTamil;
        tamilLang.localName = @"தமிழ்";
        tamilLang.flagEmoji = @"🇮🇳";
        [allLanguages setObject:tamilLang forKey:EZLanguageTamil];

        EZLanguageClass *urduLang = [[EZLanguageClass alloc] init];
        urduLang.chineseName = @"乌尔都语";
        urduLang.englishName = EZLanguageUrdu;
        urduLang.localName = @"اردو";
        urduLang.flagEmoji = @"🇮🇳";
        [allLanguages setObject:urduLang forKey:EZLanguageUrdu];

        EZLanguageClass *filipinoLang = [[EZLanguageClass alloc] init];
        filipinoLang.chineseName = @"菲律宾语";
        filipinoLang.englishName = EZLanguageFilipino;
        filipinoLang.localName = @"Filipino";
        filipinoLang.flagEmoji = @"🇵🇭";
        [allLanguages setObject:filipinoLang forKey:EZLanguageFilipino];

        EZLanguageClass *khmerLang = [[EZLanguageClass alloc] init];
        khmerLang.chineseName = @"高棉语";
        khmerLang.englishName = EZLanguageKhmer;
        khmerLang.localName = @"ភាសាខ្មែរ";
        khmerLang.flagEmoji = @"🇰🇭";
        [allLanguages setObject:khmerLang forKey:EZLanguageKhmer];

        EZLanguageClass *laoLang = [[EZLanguageClass alloc] init];
        laoLang.chineseName = @"老挝语";
        laoLang.englishName = EZLanguageLao;
        laoLang.localName = @"ພາສາລາວ";
        laoLang.flagEmoji = @"🇱🇦";
        [allLanguages setObject:laoLang forKey:EZLanguageLao];

        EZLanguageClass *bengaliLang = [[EZLanguageClass alloc] init];
        bengaliLang.chineseName = @"孟加拉语";
        bengaliLang.englishName = EZLanguageBengali;
        bengaliLang.localName = @"বাংলা";
        bengaliLang.flagEmoji = @"🇧🇩";
        [allLanguages setObject:bengaliLang forKey:EZLanguageBengali];

        EZLanguageClass *norwegianLang = [[EZLanguageClass alloc] init];
        norwegianLang.chineseName = @"挪威语";
        norwegianLang.englishName = EZLanguageNorwegian;
        norwegianLang.localName = @"Norsk";
        norwegianLang.flagEmoji = @"🇳🇴";
        [allLanguages setObject:norwegianLang forKey:EZLanguageNorwegian];

        EZLanguageClass *serbianLang = [[EZLanguageClass alloc] init];
        serbianLang.chineseName = @"塞尔维亚语";
        serbianLang.englishName = EZLanguageSerbian;
        serbianLang.localName = @"Српски";
        serbianLang.flagEmoji = @"🇷🇸";
        [allLanguages setObject:serbianLang forKey:EZLanguageSerbian];

        EZLanguageClass *croatianLang = [[EZLanguageClass alloc] init];
        croatianLang.chineseName = @"克罗地亚语";
        croatianLang.englishName = EZLanguageCroatian;
        croatianLang.localName = @"Hrvatski";
        croatianLang.flagEmoji = @"🇭🇷";
        [allLanguages setObject:croatianLang forKey:EZLanguageCroatian];

        EZLanguageClass *mongolianLang = [[EZLanguageClass alloc] init];
        mongolianLang.chineseName = @"蒙古语";
        mongolianLang.englishName = EZLanguageMongolian;
        mongolianLang.localName = @"Монгол";
        mongolianLang.flagEmoji = @"🇲🇳";
        [allLanguages setObject:mongolianLang forKey:EZLanguageMongolian];

        EZLanguageClass *hebrewLang = [[EZLanguageClass alloc] init];
        hebrewLang.chineseName = @"希伯来语";
        hebrewLang.englishName = EZLanguageHebrew;
        hebrewLang.localName = @"עברית";
        hebrewLang.flagEmoji = @"🇮🇱";
        [allLanguages setObject:hebrewLang forKey:EZLanguageHebrew];
    });

    return allLanguages;
}

@end
