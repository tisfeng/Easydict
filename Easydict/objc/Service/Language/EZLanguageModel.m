//
//  EZLanguageModel.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLanguageModel.h"


NSString *const EZLanguageAuto = @"auto";
NSString *const EZLanguageSimplifiedChinese = @"Simplified-Chinese";
NSString *const EZLanguageTraditionalChinese = @"Traditional-Chinese";
NSString *const EZLanguageClassicalChinese = @"Classical-Chinese";
NSString *const EZLanguageEnglish = @"English";
NSString *const EZLanguageJapanese = @"Japanese";
NSString *const EZLanguageKorean = @"Korean";
NSString *const EZLanguageFrench = @"French";
NSString *const EZLanguageSpanish = @"Spanish";
NSString *const EZLanguagePortuguese = @"Portuguese";
NSString *const EZLanguageBrazilianPortuguese = @"Brazilian-Portuguese";
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
NSString *const EZLanguageBurmese = @"Burmese";
NSString *const EZLanguageNorwegian = @"Norwegian";
NSString *const EZLanguageSerbian = @"Serbian";
NSString *const EZLanguageCroatian = @"Croatian";
NSString *const EZLanguageMongolian = @"Mongolian";
NSString *const EZLanguageHebrew = @"Hebrew";
NSString *const EZLanguageGeorgian = @"Georgian";
NSString *const EZLanguageUyghur = @"Uyghur";

NSString *const EZLanguageUnsupported = @"unsupported";


@implementation EZLanguageModel

// 目前总计支持 51 种语言：简体中文，繁体中文，文言文，英语，日语，韩语，法语，西班牙语，葡萄牙语，意大利语，德语，俄语，阿拉伯语，瑞典语，罗马尼亚语，泰语，斯洛伐克语，荷兰语，匈牙利语，希腊语，丹麦语，芬兰语，波兰语，捷克语，土耳其语，立陶宛语，拉脱维亚语，乌克兰语，保加利亚语，印尼语，马来语，斯洛文尼亚语，爱沙尼亚语，越南语，波斯语，印地语，泰卢固语，泰米尔语，乌尔都语，菲律宾语，高棉语，老挝语，孟加拉语，缅甸语，挪威语，塞尔维亚语，克罗地亚语，蒙古语，希伯来语，格鲁吉亚语，维吾尔语。
+ (MMOrderedDictionary *)allLanguagesDict {
    static MMOrderedDictionary *allLanguages;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allLanguages = [[MMOrderedDictionary alloc] init];

        EZLanguageModel *autoLang = [[EZLanguageModel alloc] init];
        autoLang.chineseName = @"自动检测";
        autoLang.englishName = EZLanguageAuto;
        autoLang.nativeName = @"auto";
        autoLang.flagEmoji = @"🌐";
        autoLang.code = @"und"; // BCP-47 code, und = undetermined
        [allLanguages setObject:autoLang forKey:EZLanguageAuto];

        EZLanguageModel *chineseSimplifiedLang = [[EZLanguageModel alloc] init];
        chineseSimplifiedLang.chineseName = @"简体中文";
        chineseSimplifiedLang.englishName = EZLanguageSimplifiedChinese;
        chineseSimplifiedLang.nativeName = @"简体中文";
        chineseSimplifiedLang.flagEmoji = @"🇨🇳";
        chineseSimplifiedLang.voiceLocaleIdentifier = @"zh_CN";
        chineseSimplifiedLang.code = @"zh-Hans"; // BCP-47 code
        [allLanguages setObject:chineseSimplifiedLang forKey:EZLanguageSimplifiedChinese];

        EZLanguageModel *chineseTraditionalLang = [[EZLanguageModel alloc] init];
        chineseTraditionalLang.chineseName = @"繁体中文";
        chineseTraditionalLang.englishName = EZLanguageTraditionalChinese;
        chineseTraditionalLang.nativeName = @"繁體中文";
        chineseTraditionalLang.flagEmoji = @"🇭🇰";
        chineseTraditionalLang.voiceLocaleIdentifier = @"zh_TW";
        chineseTraditionalLang.code = @"zh-Hant";
        [allLanguages setObject:chineseTraditionalLang forKey:EZLanguageTraditionalChinese];

        EZLanguageModel *chineseClassicalLang = [[EZLanguageModel alloc] init];
        chineseClassicalLang.chineseName = @"文言文";
        chineseClassicalLang.englishName = EZLanguageClassicalChinese;
        chineseClassicalLang.nativeName = @"文言文";
        chineseClassicalLang.flagEmoji = @"📜";
        chineseClassicalLang.voiceLocaleIdentifier = @"zh_CN";
        chineseClassicalLang.code = @"lzh";
        [allLanguages setObject:chineseClassicalLang forKey:EZLanguageClassicalChinese];

        EZLanguageModel *englishLang = [[EZLanguageModel alloc] init];
        englishLang.chineseName = @"英语";
        englishLang.englishName = EZLanguageEnglish;
        englishLang.nativeName = @"English";
        englishLang.flagEmoji = @"🇬🇧";
        englishLang.voiceLocaleIdentifier = @"en_US";
        englishLang.code = @"en";
        [allLanguages setObject:englishLang forKey:EZLanguageEnglish];

        EZLanguageModel *japaneseLang = [[EZLanguageModel alloc] init];
        japaneseLang.chineseName = @"日语";
        japaneseLang.englishName = EZLanguageJapanese;
        japaneseLang.nativeName = @"日本語";
        japaneseLang.flagEmoji = @"🇯🇵";
        japaneseLang.voiceLocaleIdentifier = @"ja_JP";
        japaneseLang.code = @"ja";
        [allLanguages setObject:japaneseLang forKey:EZLanguageJapanese];

        EZLanguageModel *koreanLang = [[EZLanguageModel alloc] init];
        koreanLang.chineseName = @"韩语";
        koreanLang.englishName = EZLanguageKorean;
        koreanLang.nativeName = @"한국어";
        koreanLang.flagEmoji = @"🇰🇷";
        koreanLang.voiceLocaleIdentifier = @"ko_KR";
        koreanLang.code = @"ko";
        [allLanguages setObject:koreanLang forKey:EZLanguageKorean];

        EZLanguageModel *frenchLang = [[EZLanguageModel alloc] init];
        frenchLang.chineseName = @"法语";
        frenchLang.englishName = EZLanguageFrench;
        frenchLang.nativeName = @"Français";
        frenchLang.flagEmoji = @"🇫🇷";
        frenchLang.voiceLocaleIdentifier = @"fr_FR";
        frenchLang.code = @"fr";
        [allLanguages setObject:frenchLang forKey:EZLanguageFrench];

        EZLanguageModel *spanishLang = [[EZLanguageModel alloc] init];
        spanishLang.chineseName = @"西班牙语";
        spanishLang.englishName = EZLanguageSpanish;
        spanishLang.nativeName = @"Español";
        spanishLang.flagEmoji = @"🇪🇸";
        spanishLang.voiceLocaleIdentifier = @"es_ES";
        spanishLang.code = @"es";
        [allLanguages setObject:spanishLang forKey:EZLanguageSpanish];

        EZLanguageModel *portuguese = [[EZLanguageModel alloc] init];
        portuguese.chineseName = @"葡萄牙语";
        portuguese.englishName = EZLanguagePortuguese;
        portuguese.nativeName = @"Português";
        portuguese.flagEmoji = @"🇵🇹";
        portuguese.voiceLocaleIdentifier = @"pt_PT";
        portuguese.code = @"pt";
        [allLanguages setObject:portuguese forKey:EZLanguagePortuguese];

        EZLanguageModel *brazilianPortuguese = [[EZLanguageModel alloc] init];
        brazilianPortuguese.chineseName = @"葡萄牙语（巴西）";
        brazilianPortuguese.englishName = EZLanguageBrazilianPortuguese;
        brazilianPortuguese.nativeName = @"Português (Brasil)";
        brazilianPortuguese.flagEmoji = @"🇧🇷";
        brazilianPortuguese.voiceLocaleIdentifier = @"pt_BR";
        brazilianPortuguese.code = @"pt-BR";
        [allLanguages setObject:brazilianPortuguese forKey:EZLanguageBrazilianPortuguese];

        EZLanguageModel *italianLang = [[EZLanguageModel alloc] init];
        italianLang.chineseName = @"意大利语";
        italianLang.englishName = EZLanguageItalian;
        italianLang.nativeName = @"Italiano";
        italianLang.flagEmoji = @"🇮🇹";
        italianLang.voiceLocaleIdentifier = @"it_IT";
        italianLang.code = @"it";
        [allLanguages setObject:italianLang forKey:EZLanguageItalian];

        EZLanguageModel *germanLang = [[EZLanguageModel alloc] init];
        germanLang.chineseName = @"德语";
        germanLang.englishName = EZLanguageGerman;
        germanLang.nativeName = @"Deutsch";
        germanLang.flagEmoji = @"🇩🇪";
        germanLang.voiceLocaleIdentifier = @"de_DE";
        germanLang.code = @"de";
        [allLanguages setObject:germanLang forKey:EZLanguageGerman];

        EZLanguageModel *russianLang = [[EZLanguageModel alloc] init];
        russianLang.chineseName = @"俄语";
        russianLang.englishName = EZLanguageRussian;
        russianLang.nativeName = @"Русский";
        russianLang.flagEmoji = @"🇷🇺";
        russianLang.voiceLocaleIdentifier = @"ru_RU";
        russianLang.code = @"ru";
        [allLanguages setObject:russianLang forKey:EZLanguageRussian];

        EZLanguageModel *arabicLang = [[EZLanguageModel alloc] init];
        arabicLang.chineseName = @"阿拉伯语";
        arabicLang.englishName = EZLanguageArabic;
        arabicLang.nativeName = @"العربية";
        arabicLang.flagEmoji = @"🇸🇦";
        arabicLang.voiceLocaleIdentifier = @"ar_AE";
        arabicLang.code = @"ar";
        [allLanguages setObject:arabicLang forKey:EZLanguageArabic];

        EZLanguageModel *swedishLang = [[EZLanguageModel alloc] init];
        swedishLang.chineseName = @"瑞典语";
        swedishLang.englishName = EZLanguageSwedish;
        swedishLang.nativeName = @"Svenska";
        swedishLang.flagEmoji = @"🇸🇪";
        swedishLang.voiceLocaleIdentifier = @"sv_SE";
        swedishLang.code = @"sv";
        [allLanguages setObject:swedishLang forKey:EZLanguageSwedish];

        EZLanguageModel *romanianLang = [[EZLanguageModel alloc] init];
        romanianLang.chineseName = @"罗马尼亚语";
        romanianLang.englishName = EZLanguageRomanian;
        romanianLang.nativeName = @"Română";
        romanianLang.flagEmoji = @"🇷🇴";
        romanianLang.voiceLocaleIdentifier = @"ro_RO";
        romanianLang.code = @"ro";
        [allLanguages setObject:romanianLang forKey:EZLanguageRomanian];

        EZLanguageModel *thaLang = [[EZLanguageModel alloc] init];
        thaLang.chineseName = @"泰语";
        thaLang.englishName = EZLanguageThai;
        thaLang.nativeName = @"ไทย";
        thaLang.flagEmoji = @"🇹🇭";
        thaLang.voiceLocaleIdentifier = @"th_TH";
        thaLang.code = @"th";
        [allLanguages setObject:thaLang forKey:EZLanguageThai];

        EZLanguageModel *slovakLang = [[EZLanguageModel alloc] init];
        slovakLang.chineseName = @"斯洛伐克语";
        slovakLang.englishName = EZLanguageSlovak;
        slovakLang.nativeName = @"Slovenčina";
        slovakLang.flagEmoji = @"🇸🇰";
        slovakLang.voiceLocaleIdentifier = @"sk_SK";
        slovakLang.code = @"sk";
        [allLanguages setObject:slovakLang forKey:EZLanguageSlovak];

        EZLanguageModel *dutchLang = [[EZLanguageModel alloc] init];
        dutchLang.chineseName = @"荷兰语";
        dutchLang.englishName = EZLanguageDutch;
        dutchLang.nativeName = @"Nederlands";
        dutchLang.flagEmoji = @"🇳🇱";
        dutchLang.voiceLocaleIdentifier = @"nl_NL";
        dutchLang.code = @"nl";
        [allLanguages setObject:dutchLang forKey:EZLanguageDutch];

        EZLanguageModel *hungarianLang = [[EZLanguageModel alloc] init];
        hungarianLang.chineseName = @"匈牙利语";
        hungarianLang.englishName = EZLanguageHungarian;
        hungarianLang.nativeName = @"Magyar";
        hungarianLang.flagEmoji = @"🇭🇺";
        hungarianLang.voiceLocaleIdentifier = @"hu_HU";
        hungarianLang.code = @"hu";
        [allLanguages setObject:hungarianLang forKey:EZLanguageHungarian];

        EZLanguageModel *greekLang = [[EZLanguageModel alloc] init];
        greekLang.chineseName = @"希腊语";
        greekLang.englishName = EZLanguageGreek;
        greekLang.nativeName = @"Ελληνικά";
        greekLang.flagEmoji = @"🇬🇷";
        greekLang.voiceLocaleIdentifier = @"el_GR";
        greekLang.code = @"el";
        [allLanguages setObject:greekLang forKey:EZLanguageGreek];

        EZLanguageModel *danishLang = [[EZLanguageModel alloc] init];
        danishLang.chineseName = @"丹麦语";
        danishLang.englishName = EZLanguageDanish;
        danishLang.nativeName = @"Dansk";
        danishLang.flagEmoji = @"🇩🇰";
        danishLang.voiceLocaleIdentifier = @"da_DK";
        danishLang.code = @"da";
        [allLanguages setObject:danishLang forKey:EZLanguageDanish];

        EZLanguageModel *finnishLang = [[EZLanguageModel alloc] init];
        finnishLang.chineseName = @"芬兰语";
        finnishLang.englishName = EZLanguageFinnish;
        finnishLang.nativeName = @"Suomi";
        finnishLang.flagEmoji = @"🇫🇮";
        finnishLang.voiceLocaleIdentifier = @"fi_FI";
        finnishLang.code = @"fi";
        [allLanguages setObject:finnishLang forKey:EZLanguageFinnish];

        EZLanguageModel *polishLang = [[EZLanguageModel alloc] init];
        polishLang.chineseName = @"波兰语";
        polishLang.englishName = EZLanguagePolish;
        polishLang.nativeName = @"Polski";
        polishLang.flagEmoji = @"🇵🇱";
        polishLang.voiceLocaleIdentifier = @"pl_PL";
        polishLang.code = @"pl";
        [allLanguages setObject:polishLang forKey:EZLanguagePolish];

        EZLanguageModel *czechLang = [[EZLanguageModel alloc] init];
        czechLang.chineseName = @"捷克语";
        czechLang.englishName = EZLanguageCzech;
        czechLang.nativeName = @"Čeština";
        czechLang.flagEmoji = @"🇨🇿";
        czechLang.voiceLocaleIdentifier = @"cs_CZ";
        czechLang.code = @"cs";
        [allLanguages setObject:czechLang forKey:EZLanguageCzech];

        EZLanguageModel *turkishLang = [[EZLanguageModel alloc] init];
        turkishLang.chineseName = @"土耳其语";
        turkishLang.englishName = EZLanguageTurkish;
        turkishLang.nativeName = @"Türkçe";
        turkishLang.flagEmoji = @"🇹🇷";
        turkishLang.voiceLocaleIdentifier = @"tr_TR";
        turkishLang.code = @"tr";
        [allLanguages setObject:turkishLang forKey:EZLanguageTurkish];

        EZLanguageModel *lituanianLang = [[EZLanguageModel alloc] init];
        lituanianLang.chineseName = @"立陶宛语";
        lituanianLang.englishName = EZLanguageLithuanian;
        lituanianLang.nativeName = @"Lietuvių";
        lituanianLang.flagEmoji = @"🇱🇹";
        lituanianLang.voiceLocaleIdentifier = @"lt_LT";
        lituanianLang.code = @"lt";
        [allLanguages setObject:lituanianLang forKey:EZLanguageLithuanian];

        EZLanguageModel *latvianLang = [[EZLanguageModel alloc] init];
        latvianLang.chineseName = @"拉脱维亚语";
        latvianLang.englishName = EZLanguageLatvian;
        latvianLang.nativeName = @"Latviešu";
        latvianLang.flagEmoji = @"🇱🇻";
        latvianLang.voiceLocaleIdentifier = @"lv_LV";
        latvianLang.code = @"lv";
        [allLanguages setObject:latvianLang forKey:EZLanguageLatvian];

        EZLanguageModel *ukrainianLang = [[EZLanguageModel alloc] init];
        ukrainianLang.chineseName = @"乌克兰语";
        ukrainianLang.englishName = EZLanguageUkrainian;
        ukrainianLang.nativeName = @"Українська";
        ukrainianLang.flagEmoji = @"🇺🇦";
        ukrainianLang.voiceLocaleIdentifier = @"uk_UA";
        ukrainianLang.code = @"uk";
        [allLanguages setObject:ukrainianLang forKey:EZLanguageUkrainian];

        EZLanguageModel *bulgarianLang = [[EZLanguageModel alloc] init];
        bulgarianLang.chineseName = @"保加利亚语";
        bulgarianLang.englishName = EZLanguageBulgarian;
        bulgarianLang.nativeName = @"Български";
        bulgarianLang.flagEmoji = @"🇧🇬";
        bulgarianLang.voiceLocaleIdentifier = @"bg_BG";
        bulgarianLang.code = @"bg";
        [allLanguages setObject:bulgarianLang forKey:EZLanguageBulgarian];

        EZLanguageModel *indonesianLang = [[EZLanguageModel alloc] init];
        indonesianLang.chineseName = @"印尼语";
        indonesianLang.englishName = EZLanguageIndonesian;
        indonesianLang.nativeName = @"Bahasa Indonesia";
        indonesianLang.flagEmoji = @"🇮🇩";
        indonesianLang.voiceLocaleIdentifier = @"id_ID";
        indonesianLang.code = @"id";
        [allLanguages setObject:indonesianLang forKey:EZLanguageIndonesian];

        EZLanguageModel *malayLang = [[EZLanguageModel alloc] init];
        malayLang.chineseName = @"马来语";
        malayLang.englishName = EZLanguageMalay;
        malayLang.nativeName = @"Bahasa Melayu";
        malayLang.flagEmoji = @"🇲🇾";
        malayLang.voiceLocaleIdentifier = @"ms_MY";
        malayLang.code = @"ms";
        [allLanguages setObject:malayLang forKey:EZLanguageMalay];

        EZLanguageModel *slovenian = [[EZLanguageModel alloc] init];
        slovenian.chineseName = @"斯洛文尼亚语";
        slovenian.englishName = EZLanguageSlovenian;
        slovenian.nativeName = @"Slovenščina";
        slovenian.flagEmoji = @"🇸🇮";
        slovenian.voiceLocaleIdentifier = @"sl_SI";
        slovenian.code = @"sl";
        [allLanguages setObject:slovenian forKey:EZLanguageSlovenian];

        EZLanguageModel *estonianLang = [[EZLanguageModel alloc] init];
        estonianLang.chineseName = @"爱沙尼亚语";
        estonianLang.englishName = EZLanguageEstonian;
        estonianLang.nativeName = @"Eesti";
        estonianLang.flagEmoji = @"🇪🇪";
        estonianLang.voiceLocaleIdentifier = @"et_EE";
        estonianLang.code = @"et";
        [allLanguages setObject:estonianLang forKey:EZLanguageEstonian];

        EZLanguageModel *vietnameseLang = [[EZLanguageModel alloc] init];
        vietnameseLang.chineseName = @"越南语";
        vietnameseLang.englishName = EZLanguageVietnamese;
        vietnameseLang.nativeName = @"Tiếng Việt";
        vietnameseLang.flagEmoji = @"🇻🇳";
        vietnameseLang.voiceLocaleIdentifier = @"vi_VN";
        vietnameseLang.code = @"vi";
        [allLanguages setObject:vietnameseLang forKey:EZLanguageVietnamese];

        EZLanguageModel *persianLang = [[EZLanguageModel alloc] init];
        persianLang.chineseName = @"波斯语";
        persianLang.englishName = EZLanguagePersian;
        persianLang.nativeName = @"فارسی";
        persianLang.flagEmoji = @"🇮🇷";
        persianLang.voiceLocaleIdentifier = @"fa_IR";
        persianLang.code = @"fa";
        [allLanguages setObject:persianLang forKey:EZLanguagePersian];

        EZLanguageModel *hindiLang = [[EZLanguageModel alloc] init];
        hindiLang.chineseName = @"印地语";
        hindiLang.englishName = EZLanguageHindi;
        hindiLang.nativeName = @"हिन्दी";
        hindiLang.flagEmoji = @"🇮🇳";
        hindiLang.voiceLocaleIdentifier = @"hi_IN";
        hindiLang.code = @"hi";
        [allLanguages setObject:hindiLang forKey:EZLanguageHindi];

        EZLanguageModel *teluguLang = [[EZLanguageModel alloc] init];
        teluguLang.chineseName = @"泰卢固语";
        teluguLang.englishName = EZLanguageTelugu;
        teluguLang.nativeName = @"తెలుగు";
        teluguLang.flagEmoji = @"🇮🇳";
        teluguLang.voiceLocaleIdentifier = @"te_IN";
        teluguLang.code = @"te";
        [allLanguages setObject:teluguLang forKey:EZLanguageTelugu];

        EZLanguageModel *tamilLang = [[EZLanguageModel alloc] init];
        tamilLang.chineseName = @"泰米尔语";
        tamilLang.englishName = EZLanguageTamil;
        tamilLang.nativeName = @"தமிழ்";
        tamilLang.flagEmoji = @"🇮🇳";
        tamilLang.voiceLocaleIdentifier = @"ta_IN";
        tamilLang.code = @"ta";
        [allLanguages setObject:tamilLang forKey:EZLanguageTamil];

        EZLanguageModel *urduLang = [[EZLanguageModel alloc] init];
        urduLang.chineseName = @"乌尔都语";
        urduLang.englishName = EZLanguageUrdu;
        urduLang.nativeName = @"اردو";
        urduLang.flagEmoji = @"🇮🇳";
        urduLang.voiceLocaleIdentifier = @"ur_PK";
        urduLang.code = @"ur";
        [allLanguages setObject:urduLang forKey:EZLanguageUrdu];

        EZLanguageModel *filipinoLang = [[EZLanguageModel alloc] init];
        filipinoLang.chineseName = @"菲律宾语";
        filipinoLang.englishName = EZLanguageFilipino;
        filipinoLang.nativeName = @"Filipino";
        filipinoLang.flagEmoji = @"🇵🇭";
        filipinoLang.voiceLocaleIdentifier = @"fil_PH";
        filipinoLang.code = @"fil";
        [allLanguages setObject:filipinoLang forKey:EZLanguageFilipino];

        EZLanguageModel *khmerLang = [[EZLanguageModel alloc] init];
        khmerLang.chineseName = @"高棉语";
        khmerLang.englishName = EZLanguageKhmer;
        khmerLang.nativeName = @"ភាសាខ្មែរ";
        khmerLang.flagEmoji = @"🇰🇭";
        khmerLang.voiceLocaleIdentifier = @"km_KH";
        khmerLang.code = @"km";
        [allLanguages setObject:khmerLang forKey:EZLanguageKhmer];

        EZLanguageModel *laoLang = [[EZLanguageModel alloc] init];
        laoLang.chineseName = @"老挝语";
        laoLang.englishName = EZLanguageLao;
        laoLang.nativeName = @"ພາສາລາວ";
        laoLang.flagEmoji = @"🇱🇦";
        laoLang.voiceLocaleIdentifier = @"lo_LA";
        laoLang.code = @"lo";
        [allLanguages setObject:laoLang forKey:EZLanguageLao];

        EZLanguageModel *bengaliLang = [[EZLanguageModel alloc] init];
        bengaliLang.chineseName = @"孟加拉语";
        bengaliLang.englishName = EZLanguageBengali;
        bengaliLang.nativeName = @"বাংলা";
        bengaliLang.flagEmoji = @"🇧🇩";
        bengaliLang.voiceLocaleIdentifier = @"bn_BD";
        bengaliLang.code = @"bn";
        [allLanguages setObject:bengaliLang forKey:EZLanguageBengali];

        EZLanguageModel *burmeseLang = [[EZLanguageModel alloc] init];
        burmeseLang.chineseName = @"缅甸语";
        burmeseLang.englishName = EZLanguageBurmese;
        burmeseLang.nativeName = @"ဗမာစာ";
        burmeseLang.flagEmoji = @"🇲🇲";
        burmeseLang.voiceLocaleIdentifier = @"my_MM";
        burmeseLang.code = @"my";
        [allLanguages setObject:burmeseLang forKey:EZLanguageBurmese];

        EZLanguageModel *norwegianLang = [[EZLanguageModel alloc] init];
        norwegianLang.chineseName = @"挪威语";
        norwegianLang.englishName = EZLanguageNorwegian;
        norwegianLang.nativeName = @"Norsk";
        norwegianLang.flagEmoji = @"🇳🇴";
        norwegianLang.voiceLocaleIdentifier = @"nb_NO";
        norwegianLang.code = @"nb";
        [allLanguages setObject:norwegianLang forKey:EZLanguageNorwegian];

        EZLanguageModel *serbianLang = [[EZLanguageModel alloc] init];
        serbianLang.chineseName = @"塞尔维亚语";
        serbianLang.englishName = EZLanguageSerbian;
        serbianLang.nativeName = @"Српски";
        serbianLang.flagEmoji = @"🇷🇸";
        serbianLang.voiceLocaleIdentifier = @"sr_Cyrl";
        serbianLang.code = @"sr-Cyrl";
        [allLanguages setObject:serbianLang forKey:EZLanguageSerbian];

        EZLanguageModel *croatianLang = [[EZLanguageModel alloc] init];
        croatianLang.chineseName = @"克罗地亚语";
        croatianLang.englishName = EZLanguageCroatian;
        croatianLang.nativeName = @"Hrvatski";
        croatianLang.flagEmoji = @"🇭🇷";
        croatianLang.voiceLocaleIdentifier = @"hr_HR";
        croatianLang.code = @"hr";
        [allLanguages setObject:croatianLang forKey:EZLanguageCroatian];

        EZLanguageModel *mongolianLang = [[EZLanguageModel alloc] init];
        mongolianLang.chineseName = @"蒙古语";
        mongolianLang.englishName = EZLanguageMongolian;
        mongolianLang.nativeName = @"Монгол";
        mongolianLang.flagEmoji = @"🇲🇳";
        mongolianLang.voiceLocaleIdentifier = @"mn_MN";
        mongolianLang.code = @"mn-Mong";
        [allLanguages setObject:mongolianLang forKey:EZLanguageMongolian];

        EZLanguageModel *hebrewLang = [[EZLanguageModel alloc] init];
        hebrewLang.chineseName = @"希伯来语";
        hebrewLang.englishName = EZLanguageHebrew;
        hebrewLang.nativeName = @"עברית";
        hebrewLang.flagEmoji = @"🇮🇱";
        hebrewLang.voiceLocaleIdentifier = @"he_IL";
        hebrewLang.code = @"he";
        [allLanguages setObject:hebrewLang forKey:EZLanguageHebrew];
        
        EZLanguageModel *georgianLang = [[EZLanguageModel alloc] init];
        georgianLang.chineseName = @"格鲁吉亚语";
        georgianLang.englishName = EZLanguageGeorgian;
        georgianLang.nativeName = @"ქართული";
        georgianLang.flagEmoji = @"🇬🇪";
        georgianLang.voiceLocaleIdentifier = @"ka_GE";
        georgianLang.code = @"ka";
        [allLanguages setObject:georgianLang forKey:EZLanguageGeorgian];

        EZLanguageModel *uyghurLang = [[EZLanguageModel alloc] init];
        uyghurLang.chineseName = @"维吾尔语";
        uyghurLang.englishName = EZLanguageUyghur;
        uyghurLang.nativeName = @"ئۇيغۇرچە";
        uyghurLang.flagEmoji = @"🇨🇳";
        uyghurLang.voiceLocaleIdentifier = @"ug_CN";
        uyghurLang.code = @"ug";
        [allLanguages setObject:uyghurLang forKey:EZLanguageUyghur];
    });

    return allLanguages;
}

@end
