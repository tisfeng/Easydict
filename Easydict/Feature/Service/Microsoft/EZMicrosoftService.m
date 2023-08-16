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

@interface EZMicrosoftService()
@property (nonatomic, strong) EZMicrosoftRequest *request;
@property (nonatomic, assign) BOOL canRetry;
@end

@implementation EZMicrosoftService

- (instancetype)init {
    if (self = [super init]) {
        _canRetry = YES;
        _request = [[EZMicrosoftRequest alloc] init];
    }
    return self;
}

#pragma mark - override
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
            EZLanguageAuto, @"auto-detect",
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
        @try {
            if (translateError) {
                self.result.error = translateError;
                NSLog(@"microsoft translate error %@", translateError);
            } else {
                BOOL needRetry;
                NSError * error = [self processTranslateResult:translateData text:text from:from to:to needRetry: &needRetry];
                // canRetry用来避免递归调用，code205只主动重试一次。
                if (self.canRetry && needRetry) {
                    self.canRetry = NO;
                    [self translate:text from:from to:to completion:completion];
                    return;
                }
                self.canRetry = YES;
                if (error) {
                    self.result.error = error;
                    completion(self.result, error);
                    return;
                }
                if (lookupError) {
                    NSLog(@"microsoft lookup error %@", lookupError);
                } else {
                    [self processWordSimpleWordAndPart:lookupData];
                }
            }
            completion(self.result ,translateError);
        } @catch (NSException *exception) {
            MMLogInfo(@"微软翻译接口数据解析异常 %@", exception);
            completion(self.result, EZTranslateError(EZErrorTypeAPI, @"microsoft translate data parse failed", exception));
        }
    }];
}
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *from = [self languageCodeForLanguage:queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:queryModel.queryTargetLanguage];
    NSString *maxText = [self maxTextLength:queryModel.inputText fromLanguage:queryModel.queryFromLanguage];
    NSString *text = [maxText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSString stringWithFormat:@"%@/?text=%@&from=%@&to=%@", getTranslatorHost(), text, from, to];
}

- (NSString *)name {
    return NSLocalizedString(@"microsoft_translate", nil);
}

- (EZServiceType)serviceType {
    return EZServiceTypeMicrosoft;
}

#pragma mark - private
- (NSString *)maxTextLength:(NSString *)text fromLanguage:(EZLanguage)from {
    if(text.length > 1000) {
        return [text substringToIndex:1000];
    }
    return text;
}

- (nullable NSError *)processTranslateResult:(NSData *)translateData text:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to needRetry:(BOOL *)needRetry {
    if (translateData.length == 0) {
        return EZTranslateError(EZErrorTypeAPI, @"microsoft translate data is empty", nil);
    }
    NSArray *json = [NSJSONSerialization JSONObjectWithData:translateData options:0 error:nil];
    if (![json isKindOfClass:[NSArray class]]) {
        NSString *msg = [NSString stringWithFormat:@"microsoft json parse failed\n%@", json];
        if ([json isKindOfClass:[NSDictionary class]]) {
            // 通过测试发现205应该是token失效，需要重新获取token
            if ([((NSDictionary *)json)[@"statusCode"] intValue] == 205) {
                msg = @"token invalid, please try again or restart the app.";
                [self.request reset];
                if (needRetry) {
                    *needRetry = YES;
                }
            }
        }
        return EZTranslateError(EZErrorTypeAPI, msg, nil);
    }
    EZMicrosoftTranslateModel *translateModel = [EZMicrosoftTranslateModel mj_objectArrayWithKeyValuesArray:json].firstObject;
    self.result.from = translateModel.detectedLanguage.language ? [self languageEnumFromCode:translateModel.detectedLanguage.language] : from;
    self.result.to = translateModel.translations.firstObject.to ? [self languageEnumFromCode:translateModel.translations.firstObject.to] : to;
    
    // phonetic
    if (json.count >= 2 && [json[1] isKindOfClass:[NSDictionary class]]) {
        NSString *inputTransliteration = json[1][@"inputTransliteration"];
        EZWordPhonetic *phonetic = [EZWordPhonetic new];
        phonetic.name = NSLocalizedString(@"us_phonetic", nil);
        if ([EZLanguageManager.shared isChineseLanguage:self.result.from]) {
            phonetic.name = NSLocalizedString(@"chinese_phonetic", nil);
            // 中文超过4个字感觉没必要展示拼音了，拼音会特别长。
            if (text.length > 4) {
                goto outer;
            }
        }
        phonetic.value = inputTransliteration;
        // https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/language-support?tabs=tts#supported-languages
//        phonetic.speakURL = result.fromSpeakURL;
        phonetic.language = self.result.queryModel.queryFromLanguage;
        phonetic.word = text;
        
        if (!self.result.wordResult) {
            self.result.wordResult = [EZTranslateWordResult new];
        }
        self.result.wordResult.phonetics = @[phonetic];
    }
outer:
    self.result.raw = translateData;
    self.result.translatedResults = [translateModel.translations mm_map:^id _Nullable(EZMicrosoftTranslationsModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return obj.text;
    }];
    return nil;
}

- (void)processWordSimpleWordAndPart:(NSData *)lookupData {
    if (!lookupData) return;
    NSArray *lookupJson = [NSJSONSerialization JSONObjectWithData:lookupData options:0 error:nil];
    if ([lookupJson isKindOfClass:[NSArray class]]) {
        EZMicrosoftLookupModel *lookupModel = [EZMicrosoftLookupModel mj_objectArrayWithKeyValuesArray:lookupJson].firstObject;
        EZTranslateWordResult *wordResult = self.result.wordResult ?: [EZTranslateWordResult new];
        NSMutableDictionary<NSString *, NSMutableArray<EZMicrosoftLookupTranslationsModel *> *> *tags = [NSMutableDictionary dictionary];
        for (EZMicrosoftLookupTranslationsModel *translation in lookupModel.translations) {
            NSMutableArray<EZMicrosoftLookupTranslationsModel *> *array = tags[translation.posTag];
            if (!array) {
                array = [NSMutableArray array];
                tags[translation.posTag] = array;
            }
            [array addObject:translation];
        }
        
        // 中文翻译英文
        if (([self.result.from isEqualToString:EZLanguageSimplifiedChinese] || [self.result.from isEqualToString:EZLanguageTraditionalChinese]) && [self.result.to isEqualToString:EZLanguageEnglish]) {
            NSMutableArray<EZTranslateSimpleWord *> *simpleWords = [NSMutableArray array];
            [tags enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<EZMicrosoftLookupTranslationsModel *> * _Nonnull obj, BOOL * _Nonnull stop) {
                for (EZMicrosoftLookupTranslationsModel *model in obj) {
                    EZTranslateSimpleWord * simpleWord = [EZTranslateSimpleWord new];
                    simpleWord.part = [key lowercaseString];
                    simpleWord.word = model.displayTarget;
                    simpleWord.means = [model.backTranslations mm_map:^id _Nullable(EZMicrosoftLookupBackTranslationsModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        return obj.displayText;
                    }];
                    [simpleWords addObject:simpleWord];
                }
            }];
            if (simpleWords.count) {
                wordResult.simpleWords = simpleWords;
            }
        } else {
            NSMutableArray<EZTranslatePart *> *parts = [NSMutableArray array];
            [tags enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<EZMicrosoftLookupTranslationsModel *> * _Nonnull obj, BOOL * _Nonnull stop) {
                EZTranslatePart *part = [EZTranslatePart new];
                part.part = [key lowercaseString];
                part.means = [obj mm_map:^id _Nullable(EZMicrosoftLookupTranslationsModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    return obj.displayTarget;
                }];
                [parts addObject:part];
            }];
            if (parts.count) {
                wordResult.parts = [parts copy];
            }
        }
        
        if (wordResult.parts.count || wordResult.simpleWords.count) {
            self.result.wordResult = wordResult;
        }
    }
}


@end
