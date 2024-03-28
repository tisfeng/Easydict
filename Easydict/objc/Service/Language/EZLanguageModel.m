//
//  EZLanguageConst.m
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

NSString *const EZLanguageUnsupported = @"unsupported";


@implementation EZLanguageModel

// 目前总计支持 49 种语言：简体中文，繁体中文，文言文，英语，日语，韩语，法语，西班牙语，葡萄牙语，意大利语，德语，俄语，阿拉伯语，瑞典语，罗马尼亚语，泰语，斯洛伐克语，荷兰语，匈牙利语，希腊语，丹麦语，芬兰语，波兰语，捷克语，土耳其语，立陶宛语，拉脱维亚语，乌克兰语，保加利亚语，印尼语，马来语，斯洛文尼亚语，爱沙尼亚语，越南语，波斯语，印地语，泰卢固语，泰米尔语，乌尔都语，菲律宾语，高棉语，老挝语，孟加拉语，缅甸语，挪威语，塞尔维亚语，克罗地亚语，蒙古语，希伯来语。
+ (MMOrderedDictionary<EZLanguage, EZLanguageModel *> *)allLanguagesDict {
    static MMOrderedDictionary *allLanguages;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allLanguages = [[MMOrderedDictionary alloc] init];
        
        EZLanguageModel *autoLang = [[EZLanguageModel alloc] init];
        autoLang.chineseName = @"自动检测";
        autoLang.englishName = EZLanguageAuto;
        autoLang.localName = @"auto";
        autoLang.flagEmoji = @"🌐";
        [allLanguages setObject:autoLang forKey:EZLanguageAuto];
        
        EZLanguageModel *chineseSimplifiedLang = [[EZLanguageModel alloc] init];
        chineseSimplifiedLang.chineseName = @"简体中文";
        chineseSimplifiedLang.englishName = EZLanguageSimplifiedChinese;
        chineseSimplifiedLang.localName = @"简体中文";
        chineseSimplifiedLang.flagEmoji = @"🇨🇳";
        chineseSimplifiedLang.localeIdentifier = @"zh_CN";
        chineseSimplifiedLang.voiceName = @"Tingting";
        [allLanguages setObject:chineseSimplifiedLang forKey:EZLanguageSimplifiedChinese];
        
        EZLanguageModel *chineseTraditionalLang = [[EZLanguageModel alloc] init];
        chineseTraditionalLang.chineseName = @"繁体中文";
        chineseTraditionalLang.englishName = EZLanguageTraditionalChinese;
        chineseTraditionalLang.localName = @"繁體中文";
        chineseTraditionalLang.flagEmoji = @"🇭🇰";
        chineseTraditionalLang.localeIdentifier = @"zh_TW";
        chineseTraditionalLang.voiceName = @"Tingting";
        [allLanguages setObject:chineseTraditionalLang forKey:EZLanguageTraditionalChinese];
        
        EZLanguageModel *chineseClassicalLang = [[EZLanguageModel alloc] init];
        chineseClassicalLang.chineseName = @"文言文";
        chineseClassicalLang.englishName = EZLanguageClassicalChinese;
        chineseClassicalLang.localName = @"文言文";
        chineseClassicalLang.flagEmoji = @"📜";
        chineseClassicalLang.localeIdentifier = @"zh_CN";
        chineseClassicalLang.voiceName = @"Tingting";
        [allLanguages setObject:chineseClassicalLang forKey:EZLanguageClassicalChinese];
        
        EZLanguageModel *englishLang = [[EZLanguageModel alloc] init];
        englishLang.chineseName = @"英语";
        englishLang.englishName = EZLanguageEnglish;
        englishLang.localName = @"English";
        englishLang.flagEmoji = @"🇬🇧";
        englishLang.localeIdentifier = @"en_US";
        englishLang.voiceName = @"Samantha";
        [allLanguages setObject:englishLang forKey:EZLanguageEnglish];
        
        EZLanguageModel *japaneseLang = [[EZLanguageModel alloc] init];
        japaneseLang.chineseName = @"日语";
        japaneseLang.englishName = EZLanguageJapanese;
        japaneseLang.localName = @"日本語";
        japaneseLang.flagEmoji = @"🇯🇵";
        japaneseLang.localeIdentifier = @"ja_JP";
        japaneseLang.voiceName = @"Kyoko";
        [allLanguages setObject:japaneseLang forKey:EZLanguageJapanese];
        
        EZLanguageModel *koreanLang = [[EZLanguageModel alloc] init];
        koreanLang.chineseName = @"韩语";
        koreanLang.englishName = EZLanguageKorean;
        koreanLang.localName = @"한국어";
        koreanLang.flagEmoji = @"🇰🇷";
        koreanLang.localeIdentifier = @"ko_KR";
        koreanLang.voiceName = @"Yuna";
        [allLanguages setObject:koreanLang forKey:EZLanguageKorean];
        
        EZLanguageModel *frenchLang = [[EZLanguageModel alloc] init];
        frenchLang.chineseName = @"法语";
        frenchLang.englishName = EZLanguageFrench;
        frenchLang.localName = @"Français";
        frenchLang.flagEmoji = @"🇫🇷";
        frenchLang.localeIdentifier = @"fr_FR";
        frenchLang.voiceName = @"Amelie";
        [allLanguages setObject:frenchLang forKey:EZLanguageFrench];
        
        EZLanguageModel *spanishLang = [[EZLanguageModel alloc] init];
        spanishLang.chineseName = @"西班牙语";
        spanishLang.englishName = EZLanguageSpanish;
        spanishLang.localName = @"Español";
        spanishLang.flagEmoji = @"🇪🇸";
        spanishLang.localeIdentifier = @"es_ES";
        spanishLang.voiceName = @"Penelope";
        [allLanguages setObject:spanishLang forKey:EZLanguageSpanish];
        
        EZLanguageModel *portuguese = [[EZLanguageModel alloc] init];
        portuguese.chineseName = @"葡萄牙语";
        portuguese.englishName = EZLanguagePortuguese;
        portuguese.localName = @"Português";
        portuguese.flagEmoji = @"🇵🇹";
        portuguese.localeIdentifier = @"pt_PT";
        portuguese.voiceName = @"Luciana";
        [allLanguages setObject:portuguese forKey:EZLanguagePortuguese];
        
        EZLanguageModel *italianLang = [[EZLanguageModel alloc] init];
        italianLang.chineseName = @"意大利语";
        italianLang.englishName = EZLanguageItalian;
        italianLang.localName = @"Italiano";
        italianLang.flagEmoji = @"🇮🇹";
        italianLang.localeIdentifier = @"it_IT";
        italianLang.voiceName = @"Alice";
        [allLanguages setObject:italianLang forKey:EZLanguageItalian];
        
        EZLanguageModel *germanLang = [[EZLanguageModel alloc] init];
        germanLang.chineseName = @"德语";
        germanLang.englishName = EZLanguageGerman;
        germanLang.localName = @"Deutsch";
        germanLang.flagEmoji = @"🇩🇪";
        germanLang.localeIdentifier = @"de_DE";
        germanLang.voiceName = @"Anna";
        [allLanguages setObject:germanLang forKey:EZLanguageGerman];
        
        EZLanguageModel *russianLang = [[EZLanguageModel alloc] init];
        russianLang.chineseName = @"俄语";
        russianLang.englishName = EZLanguageRussian;
        russianLang.localName = @"Русский";
        russianLang.flagEmoji = @"🇷🇺";
        russianLang.localeIdentifier = @"ru_RU";
        russianLang.voiceName = @"Milena";
        [allLanguages setObject:russianLang forKey:EZLanguageRussian];
        
        EZLanguageModel *arabicLang = [[EZLanguageModel alloc] init];
        arabicLang.chineseName = @"阿拉伯语";
        arabicLang.englishName = EZLanguageArabic;
        arabicLang.localName = @"العربية";
        arabicLang.flagEmoji = @"🇸🇦";
        arabicLang.localeIdentifier = @"ar_AE";
        arabicLang.voiceName = @"Zuzana";
        [allLanguages setObject:arabicLang forKey:EZLanguageArabic];
        
        EZLanguageModel *swedishLang = [[EZLanguageModel alloc] init];
        swedishLang.chineseName = @"瑞典语";
        swedishLang.englishName = EZLanguageSwedish;
        swedishLang.localName = @"Svenska";
        swedishLang.flagEmoji = @"🇸🇪";
        swedishLang.localeIdentifier = @"sv_SE";
        swedishLang.voiceName = @"Alva";
        [allLanguages setObject:swedishLang forKey:EZLanguageSwedish];
        
        EZLanguageModel *romanianLang = [[EZLanguageModel alloc] init];
        romanianLang.chineseName = @"罗马尼亚语";
        romanianLang.englishName = EZLanguageRomanian;
        romanianLang.localName = @"Română";
        romanianLang.flagEmoji = @"🇷🇴";
        romanianLang.localeIdentifier = @"ro_RO";
        romanianLang.voiceName = @"Ioana";
        [allLanguages setObject:romanianLang forKey:EZLanguageRomanian];
        
        EZLanguageModel *thaLang = [[EZLanguageModel alloc] init];
        thaLang.chineseName = @"泰语";
        thaLang.englishName = EZLanguageThai;
        thaLang.localName = @"ไทย";
        thaLang.flagEmoji = @"🇹🇭";
        thaLang.localeIdentifier = @"th_TH";
        thaLang.voiceName = @"Kanya";
        [allLanguages setObject:thaLang forKey:EZLanguageThai];
        
        EZLanguageModel *slovakLang = [[EZLanguageModel alloc] init];
        slovakLang.chineseName = @"斯洛伐克语";
        slovakLang.englishName = EZLanguageSlovak;
        slovakLang.localName = @"Slovenčina";
        slovakLang.flagEmoji = @"🇸🇰";
        slovakLang.localeIdentifier = @"sk_SK";
        slovakLang.voiceName = @"Laura";
        [allLanguages setObject:slovakLang forKey:EZLanguageSlovak];
        
        EZLanguageModel *dutchLang = [[EZLanguageModel alloc] init];
        dutchLang.chineseName = @"荷兰语";
        dutchLang.englishName = EZLanguageDutch;
        dutchLang.localName = @"Nederlands";
        dutchLang.flagEmoji = @"🇳🇱";
        dutchLang.localeIdentifier = @"nl_NL";
        dutchLang.voiceName = @"Xander";
        [allLanguages setObject:dutchLang forKey:EZLanguageDutch];
        
        EZLanguageModel *hungarianLang = [[EZLanguageModel alloc] init];
        hungarianLang.chineseName = @"匈牙利语";
        hungarianLang.englishName = EZLanguageHungarian;
        hungarianLang.localName = @"Magyar";
        hungarianLang.flagEmoji = @"🇭🇺";
        hungarianLang.localeIdentifier = @"hu_HU";
        hungarianLang.voiceName = @"Ellen";
        [allLanguages setObject:hungarianLang forKey:EZLanguageHungarian];
        
        EZLanguageModel *greekLang = [[EZLanguageModel alloc] init];
        greekLang.chineseName = @"希腊语";
        greekLang.englishName = EZLanguageGreek;
        greekLang.localName = @"Ελληνικά";
        greekLang.flagEmoji = @"🇬🇷";
        greekLang.localeIdentifier = @"el_GR";
        greekLang.voiceName = @"Melina";
        [allLanguages setObject:greekLang forKey:EZLanguageGreek];
        
        EZLanguageModel *danishLang = [[EZLanguageModel alloc] init];
        danishLang.chineseName = @"丹麦语";
        danishLang.englishName = EZLanguageDanish;
        danishLang.localName = @"Dansk";
        danishLang.flagEmoji = @"🇩🇰";
        danishLang.localeIdentifier = @"da_DK";
        danishLang.voiceName = @"Naja";
        [allLanguages setObject:danishLang forKey:EZLanguageDanish];
        
        EZLanguageModel *finnishLang = [[EZLanguageModel alloc] init];
        finnishLang.chineseName = @"芬兰语";
        finnishLang.englishName = EZLanguageFinnish;
        finnishLang.localName = @"Suomi";
        finnishLang.flagEmoji = @"🇫🇮";
        finnishLang.localeIdentifier = @"fi_FI";
        finnishLang.voiceName = @"Satu";
        [allLanguages setObject:finnishLang forKey:EZLanguageFinnish];
        
        EZLanguageModel *polishLang = [[EZLanguageModel alloc] init];
        polishLang.chineseName = @"波兰语";
        polishLang.englishName = EZLanguagePolish;
        polishLang.localName = @"Polski";
        polishLang.flagEmoji = @"🇵🇱";
        polishLang.localeIdentifier = @"pl_PL";
        polishLang.voiceName = @"Ewa";
        [allLanguages setObject:polishLang forKey:EZLanguagePolish];
        
        EZLanguageModel *czechLang = [[EZLanguageModel alloc] init];
        czechLang.chineseName = @"捷克语";
        czechLang.englishName = EZLanguageCzech;
        czechLang.localName = @"Čeština";
        czechLang.flagEmoji = @"🇨🇿";
        czechLang.localeIdentifier = @"cs_CZ";
        czechLang.voiceName = @"Zuzana";
        [allLanguages setObject:czechLang forKey:EZLanguageCzech];
        
        EZLanguageModel *turkishLang = [[EZLanguageModel alloc] init];
        turkishLang.chineseName = @"土耳其语";
        turkishLang.englishName = EZLanguageTurkish;
        turkishLang.localName = @"Türkçe";
        turkishLang.flagEmoji = @"🇹🇷";
        turkishLang.localeIdentifier = @"tr_TR";
        turkishLang.voiceName = @"Filiz";
        [allLanguages setObject:turkishLang forKey:EZLanguageTurkish];
        
        EZLanguageModel *lituanianLang = [[EZLanguageModel alloc] init];
        lituanianLang.chineseName = @"立陶宛语";
        lituanianLang.englishName = EZLanguageLithuanian;
        lituanianLang.localName = @"Lietuvių";
        lituanianLang.flagEmoji = @"🇱🇹";
        lituanianLang.localeIdentifier = @"lt_LT";
        lituanianLang.voiceName = @"Rasa";
        [allLanguages setObject:lituanianLang forKey:EZLanguageLithuanian];
        
        EZLanguageModel *latvianLang = [[EZLanguageModel alloc] init];
        latvianLang.chineseName = @"拉脱维亚语";
        latvianLang.englishName = EZLanguageLatvian;
        latvianLang.localName = @"Latviešu";
        latvianLang.flagEmoji = @"🇱🇻";
        latvianLang.localeIdentifier = @"lv_LV";
        latvianLang.voiceName = @"Liga";
        [allLanguages setObject:latvianLang forKey:EZLanguageLatvian];
        
        EZLanguageModel *ukrainianLang = [[EZLanguageModel alloc] init];
        ukrainianLang.chineseName = @"乌克兰语";
        ukrainianLang.englishName = EZLanguageUkrainian;
        ukrainianLang.localName = @"Українська";
        ukrainianLang.flagEmoji = @"🇺🇦";
        ukrainianLang.localeIdentifier = @"uk_UA";
        ukrainianLang.voiceName = @"Oksana";
        [allLanguages setObject:ukrainianLang forKey:EZLanguageUkrainian];
        
        EZLanguageModel *bulgarianLang = [[EZLanguageModel alloc] init];
        bulgarianLang.chineseName = @"保加利亚语";
        bulgarianLang.englishName = EZLanguageBulgarian;
        bulgarianLang.localName = @"Български";
        bulgarianLang.flagEmoji = @"🇧🇬";
        bulgarianLang.localeIdentifier = @"bg_BG";
        bulgarianLang.voiceName = @"Tanya";
        [allLanguages setObject:bulgarianLang forKey:EZLanguageBulgarian];
        
        EZLanguageModel *indonesianLang = [[EZLanguageModel alloc] init];
        indonesianLang.chineseName = @"印尼语";
        indonesianLang.englishName = EZLanguageIndonesian;
        indonesianLang.localName = @"Bahasa Indonesia";
        indonesianLang.flagEmoji = @"🇮🇩";
        indonesianLang.localeIdentifier = @"id_ID";
        indonesianLang.voiceName = @"Damayanti";
        [allLanguages setObject:indonesianLang forKey:EZLanguageIndonesian];
        
        EZLanguageModel *malayLang = [[EZLanguageModel alloc] init];
        malayLang.chineseName = @"马来语";
        malayLang.englishName = EZLanguageMalay;
        malayLang.localName = @"Bahasa Melayu";
        malayLang.flagEmoji = @"🇲🇾";
        malayLang.localeIdentifier = @"ms_MY";
        malayLang.voiceName = @"Zhiyu";
        [allLanguages setObject:malayLang forKey:EZLanguageMalay];
        
        EZLanguageModel *slovenian = [[EZLanguageModel alloc] init];
        slovenian.chineseName = @"斯洛文尼亚语";
        slovenian.englishName = EZLanguageSlovenian;
        slovenian.localName = @"Slovenščina";
        slovenian.flagEmoji = @"🇸🇮";
        slovenian.localeIdentifier = @"sl_SI";
        slovenian.voiceName = @"Lado";
        [allLanguages setObject:slovenian forKey:EZLanguageSlovenian];
        
        EZLanguageModel *estonianLang = [[EZLanguageModel alloc] init];
        estonianLang.chineseName = @"爱沙尼亚语";
        estonianLang.englishName = EZLanguageEstonian;
        estonianLang.localName = @"Eesti";
        estonianLang.flagEmoji = @"🇪🇪";
        estonianLang.localeIdentifier = @"et_EE";
        estonianLang.voiceName = @"Karl";
        [allLanguages setObject:estonianLang forKey:EZLanguageEstonian];
        
        EZLanguageModel *vietnameseLang = [[EZLanguageModel alloc] init];
        vietnameseLang.chineseName = @"越南语";
        vietnameseLang.englishName = EZLanguageVietnamese;
        vietnameseLang.localName = @"Tiếng Việt";
        vietnameseLang.flagEmoji = @"🇻🇳";
        vietnameseLang.localeIdentifier = @"vi_VN";
        vietnameseLang.voiceName = @"An";
        [allLanguages setObject:vietnameseLang forKey:EZLanguageVietnamese];
        
        EZLanguageModel *persianLang = [[EZLanguageModel alloc] init];
        persianLang.chineseName = @"波斯语";
        persianLang.englishName = EZLanguagePersian;
        persianLang.localName = @"فارسی";
        persianLang.flagEmoji = @"🇮🇷";
        persianLang.localeIdentifier = @"fa_IR";
        persianLang.voiceName = @"Zahra";
        [allLanguages setObject:persianLang forKey:EZLanguagePersian];
        
        EZLanguageModel *hindiLang = [[EZLanguageModel alloc] init];
        hindiLang.chineseName = @"印地语";
        hindiLang.englishName = EZLanguageHindi;
        hindiLang.localName = @"हिन्दी";
        hindiLang.flagEmoji = @"🇮🇳";
        hindiLang.localeIdentifier = @"hi_IN";
        hindiLang.voiceName = @"Lekha";
        [allLanguages setObject:hindiLang forKey:EZLanguageHindi];
        
        EZLanguageModel *teluguLang = [[EZLanguageModel alloc] init];
        teluguLang.chineseName = @"泰卢固语";
        teluguLang.englishName = EZLanguageTelugu;
        teluguLang.localName = @"తెలుగు";
        teluguLang.flagEmoji = @"🇮🇳";
        teluguLang.localeIdentifier = @"te_IN";
        teluguLang.voiceName = @"Chitra";
        [allLanguages setObject:teluguLang forKey:EZLanguageTelugu];
        
        EZLanguageModel *tamilLang = [[EZLanguageModel alloc] init];
        tamilLang.chineseName = @"泰米尔语";
        tamilLang.englishName = EZLanguageTamil;
        tamilLang.localName = @"தமிழ்";
        tamilLang.flagEmoji = @"🇮🇳";
        tamilLang.localeIdentifier = @"ta_IN";
        tamilLang.voiceName = @"Kanya";
        [allLanguages setObject:tamilLang forKey:EZLanguageTamil];
        
        EZLanguageModel *urduLang = [[EZLanguageModel alloc] init];
        urduLang.chineseName = @"乌尔都语";
        urduLang.englishName = EZLanguageUrdu;
        urduLang.localName = @"اردو";
        urduLang.flagEmoji = @"🇮🇳";
        urduLang.localeIdentifier = @"ur_PK";
        urduLang.voiceName = @"Zaira";
        [allLanguages setObject:urduLang forKey:EZLanguageUrdu];
        
        EZLanguageModel *filipinoLang = [[EZLanguageModel alloc] init];
        filipinoLang.chineseName = @"菲律宾语";
        filipinoLang.englishName = EZLanguageFilipino;
        filipinoLang.localName = @"Filipino";
        filipinoLang.flagEmoji = @"🇵🇭";
        filipinoLang.localeIdentifier = @"fil_PH";
        [allLanguages setObject:filipinoLang forKey:EZLanguageFilipino];
        
        EZLanguageModel *khmerLang = [[EZLanguageModel alloc] init];
        khmerLang.chineseName = @"高棉语";
        khmerLang.englishName = EZLanguageKhmer;
        khmerLang.localName = @"ភាសាខ្មែរ";
        khmerLang.flagEmoji = @"🇰🇭";
        khmerLang.localeIdentifier = @"km_KH";
        [allLanguages setObject:khmerLang forKey:EZLanguageKhmer];
        
        EZLanguageModel *laoLang = [[EZLanguageModel alloc] init];
        laoLang.chineseName = @"老挝语";
        laoLang.englishName = EZLanguageLao;
        laoLang.localName = @"ພາສາລາວ";
        laoLang.flagEmoji = @"🇱🇦";
        laoLang.localeIdentifier = @"lo_LA";
        [allLanguages setObject:laoLang forKey:EZLanguageLao];
        
        EZLanguageModel *bengaliLang = [[EZLanguageModel alloc] init];
        bengaliLang.chineseName = @"孟加拉语";
        bengaliLang.englishName = EZLanguageBengali;
        bengaliLang.localName = @"বাংলা";
        bengaliLang.flagEmoji = @"🇧🇩";
        bengaliLang.localeIdentifier = @"bn_BD";
        [allLanguages setObject:bengaliLang forKey:EZLanguageBengali];
        
        EZLanguageModel *burmeseLang = [[EZLanguageModel alloc] init];
        burmeseLang.chineseName = @"缅甸语";
        burmeseLang.englishName = EZLanguageBurmese;
        burmeseLang.localName = @"ဗမာစာ";
        burmeseLang.flagEmoji = @"🇲🇲";
        burmeseLang.localeIdentifier = @"my_MM";
        [allLanguages setObject:burmeseLang forKey:EZLanguageBurmese];
        
        EZLanguageModel *norwegianLang = [[EZLanguageModel alloc] init];
        norwegianLang.chineseName = @"挪威语";
        norwegianLang.englishName = EZLanguageNorwegian;
        norwegianLang.localName = @"Norsk";
        norwegianLang.flagEmoji = @"🇳🇴";
        norwegianLang.localeIdentifier = @"nb_NO";
        [allLanguages setObject:norwegianLang forKey:EZLanguageNorwegian];
        
        EZLanguageModel *serbianLang = [[EZLanguageModel alloc] init];
        serbianLang.chineseName = @"塞尔维亚语";
        serbianLang.englishName = EZLanguageSerbian;
        serbianLang.localName = @"Српски";
        serbianLang.flagEmoji = @"🇷🇸";
        serbianLang.localeIdentifier = @"sr_RS";
        [allLanguages setObject:serbianLang forKey:EZLanguageSerbian];
        
        EZLanguageModel *croatianLang = [[EZLanguageModel alloc] init];
        croatianLang.chineseName = @"克罗地亚语";
        croatianLang.englishName = EZLanguageCroatian;
        croatianLang.localName = @"Hrvatski";
        croatianLang.flagEmoji = @"🇭🇷";
        croatianLang.localeIdentifier = @"hr_HR";
        [allLanguages setObject:croatianLang forKey:EZLanguageCroatian];
        
        EZLanguageModel *mongolianLang = [[EZLanguageModel alloc] init];
        mongolianLang.chineseName = @"蒙古语";
        mongolianLang.englishName = EZLanguageMongolian;
        mongolianLang.localName = @"Монгол";
        mongolianLang.flagEmoji = @"🇲🇳";
        mongolianLang.localeIdentifier = @"mn_MN";
        [allLanguages setObject:mongolianLang forKey:EZLanguageMongolian];
        
        EZLanguageModel *hebrewLang = [[EZLanguageModel alloc] init];
        hebrewLang.chineseName = @"希伯来语";
        hebrewLang.englishName = EZLanguageHebrew;
        hebrewLang.localName = @"עברית";
        hebrewLang.flagEmoji = @"🇮🇱";
        hebrewLang.localeIdentifier = @"he_IL";
        [allLanguages setObject:hebrewLang forKey:EZLanguageHebrew];
    });
    
    return allLanguages;
}

@end
