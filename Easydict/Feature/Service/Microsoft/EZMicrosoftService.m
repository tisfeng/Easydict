//
//  EZMicrosoftService.m
//  Easydict
//
//  Created by ChoiKarl on 2023/8/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZMicrosoftService.h"
#import "EZMicrosoftRequest.h"
#import "MJExtension.h"
#import "EZMicrosoftTranslateModel.h"
#import "NSArray+MM.h"

@interface EZMicrosoftService()
@property (nonatomic, strong) EZMicrosoftRequest *request;
@end

@implementation EZMicrosoftService

- (instancetype)init {
    if (self = [super init]) {
        _request = [[EZMicrosoftRequest alloc] init];
    }
    return self;
}

// TODO: copy from google service
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
            EZLanguageAuto, @"auto",
            EZLanguageSimplifiedChinese, @"zh-Hans",
            EZLanguageTraditionalChinese, @"zh-Hant",
            EZLanguageEnglish, @"en",
            EZLanguageJapanese, @"ja",
            EZLanguageKorean, @"ko",
            EZLanguageFrench, @"fr",
            EZLanguageSpanish, @"es",
            EZLanguagePortuguese, @"pt",
            EZLanguageItalian, @"it",
            EZLanguageGerman, @"de",
            EZLanguageRussian, @"ru",
            EZLanguageArabic, @"ar",
            EZLanguageSwedish, @"sv",
            EZLanguageRomanian, @"ro",
            EZLanguageThai, @"th",
            EZLanguageSlovak, @"sk",
            EZLanguageDutch, @"nl",
            EZLanguageHungarian, @"hu",
            EZLanguageGreek, @"el",
            EZLanguageDanish, @"da",
            EZLanguageFinnish, @"fi",
            EZLanguagePolish, @"pl",
            EZLanguageCzech, @"cs",
            EZLanguageTurkish, @"tr",
            EZLanguageLithuanian, @"lt",
            EZLanguageLatvian, @"lv",
            EZLanguageUkrainian, @"uk",
            EZLanguageBulgarian, @"bg",
            EZLanguageIndonesian, @"id",
            EZLanguageMalay, @"ms",
            EZLanguageSlovenian, @"sl",
            EZLanguageEstonian, @"et",
            EZLanguageVietnamese, @"vi",
            EZLanguagePersian, @"fa",
            EZLanguageHindi, @"hi",
            EZLanguageTelugu, @"te",
            EZLanguageTamil, @"ta",
            EZLanguageUrdu, @"ur",
            EZLanguageFilipino, @"fil",
            EZLanguageKhmer, @"km",
            EZLanguageLao, @"lo",
            EZLanguageBengali, @"bn",
            EZLanguageBurmese, @"my",
            EZLanguageNorwegian, @"nb",
            EZLanguageSerbian, @"sr-Cyrl",
            EZLanguageCroatian, @"hr",
            EZLanguageMongolian, @"mn-Mong",
            EZLanguageHebrew, @"he",
                    nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(nonnull EZLanguage)from to:(nonnull EZLanguage)to completion:(nonnull void (^)(EZQueryResult * _Nullable, NSError * _Nullable))completion {
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:NO from:from to:to completion:completion]) {
        return;
    }
    
    text = [self maxTextLength:text fromLanguage:from];
    NSString *fromCode = [self languageCodeForLanguage:from];
    NSString *toCode = [self languageCodeForLanguage:to];
    mm_weakify(self)
    [self.request translateWithFrom:fromCode to:toCode text:text completionHandler:^(NSData * _Nullable data, NSData * _Nullable lookup, NSError * _Nullable error) {
        mm_strongify(self)
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![json isKindOfClass:[NSArray class]]) {
            completion(nil, EZTranslateError(EZErrorTypeAPI, @"microsoft json parse failed", nil));
            return;
        }
        if (error) {
            NSLog(@"microsoft translate error %@", error);
        }
        
        EZMicrosoftTranslateModel *model = [EZMicrosoftTranslateModel mj_objectArrayWithKeyValuesArray:json].firstObject;
        
        self.result.from = [self languageEnumFromCode:model.detectedLanguage.language];
        self.result.to = [self languageEnumFromCode:model.translations.firstObject.to];
        self.result.error = error;
        self.result.raw = data;
        
        self.result.translatedResults = [model.translations mm_map:^id _Nullable(EZMicrosoftTranslationsModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return obj.text;
        }];
        completion(self.result ,error);
    }];
}

- (NSString *)maxTextLength:(NSString *)text fromLanguage:(EZLanguage)from {
    if(text.length > 1000) {
        return [text substringToIndex:1000];
    }
    return text;
}

- (NSString *)name {
    return NSLocalizedString(@"microsoft_translate", nil);
}

- (EZServiceType)serviceType {
    return EZServiceTypeMicrosoft;
}

@end
