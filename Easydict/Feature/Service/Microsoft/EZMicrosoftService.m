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
#import "EZMicrosoftLookupModel.h"
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
    [self.request translateWithFrom:fromCode to:toCode text:text completionHandler:^(NSData * _Nullable translateData, NSData * _Nullable lookupData, NSError * _Nullable translateError, NSError * _Nullable lookupError) {
        mm_strongify(self)
        if (translateError) {
            self.result.error = translateError;
            NSLog(@"microsoft translate error %@", translateError);
        }
        if (lookupError) {
            NSLog(@"microsoft lookup error %@", lookupError);
        }
        
        BOOL success = [self processTranslateResult:translateData failedCallback:^(NSError *error) {
            self.result.error = error;
            completion(nil, error);
        }];
        if (!success) return;
        
        [self processWordPart:lookupData];
        completion(self.result ,translateError);
    }];
}

- (BOOL)processTranslateResult:(NSData *)translateData failedCallback:(void(^)(NSError *))failedCallback {
    NSArray *json = [NSJSONSerialization JSONObjectWithData:translateData options:0 error:nil];
    if (![json isKindOfClass:[NSArray class]]) {
        failedCallback(EZTranslateError(EZErrorTypeAPI, @"microsoft json parse failed", nil));
        return NO;
    }
    EZMicrosoftTranslateModel *translateModel = [EZMicrosoftTranslateModel mj_objectArrayWithKeyValuesArray:json].firstObject;
    self.result.from = [self languageEnumFromCode:translateModel.detectedLanguage.language];
    self.result.to = [self languageEnumFromCode:translateModel.translations.firstObject.to];
    self.result.raw = translateData;
    self.result.translatedResults = [translateModel.translations mm_map:^id _Nullable(EZMicrosoftTranslationsModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return obj.text;
    }];
    return YES;
}

- (void)processWordPart:(NSData *)lookupData {
    if (!lookupData) return;
    NSArray *lookupJson = [NSJSONSerialization JSONObjectWithData:lookupData options:0 error:nil];
    if ([lookupJson isKindOfClass:[NSArray class]]) {
        EZMicrosoftLookupModel *lookupModel = [EZMicrosoftLookupModel mj_objectArrayWithKeyValuesArray:lookupJson].firstObject;
        NSMutableDictionary<NSString *, NSMutableArray<EZMicrosoftLookupTranslationsModel *> *> *tags = [NSMutableDictionary dictionary];
        for (EZMicrosoftLookupTranslationsModel *translation in lookupModel.translations) {
            NSMutableArray<EZMicrosoftLookupTranslationsModel *> *array = tags[translation.posTag];
            if (!array) {
                array = [NSMutableArray array];
                tags[translation.posTag] = array;
            }
            [array addObject:translation];
        }
        
        NSMutableArray<EZTranslatePart *> *parts = [NSMutableArray array];
        [tags enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<EZMicrosoftLookupTranslationsModel *> * _Nonnull obj, BOOL * _Nonnull stop) {
            EZTranslatePart *part = [EZTranslatePart new];
            part.part = key;
            part.means = [obj mm_map:^id _Nullable(EZMicrosoftLookupTranslationsModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return obj.displayTarget;
            }];
            [parts addObject:part];
        }];
        if (parts.count) {
            self.result.wordResult = [EZTranslateWordResult new];
            self.result.wordResult.parts = [parts copy];
        }
    }
}

- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *from = [self languageCodeForLanguage:queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:queryModel.queryTargetLanguage];
    NSString *maxText = [self maxTextLength:queryModel.inputText fromLanguage:queryModel.queryFromLanguage];
    NSString *text = [maxText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSString stringWithFormat:@"%@/?text=%@&from=%@&to=%@", kTranslatorHost, text, from, to];
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
