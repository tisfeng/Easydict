//
//  EZBingService.m
//  Easydict
//
//  Created by choykarl on 2023/8/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZBingService.h"
#import "EZBingRequest.h"
#import "EZBingTranslateModel.h"
#import "EZBingLookupModel.h"
#import "EZConfiguration.h"
#import "NSString+EZUtils.h"

@interface EZBingService ()
@property (nonatomic, strong) EZBingRequest *request;
@property (nonatomic, assign) BOOL canRetry;
@property (nonatomic, assign) BOOL isDictQueryResult ;
@end

@implementation EZBingService

- (instancetype)init {
    if (self = [super init]) {
        _canRetry = YES;
        _request = [[EZBingRequest alloc] init];
    }
    return self;
}

#pragma mark - override

- (EZQueryTextType)intelligentQueryTextType {
    EZQueryTextType type = [EZConfiguration.shared intelligentQueryTextTypeForServiceType:self.serviceType];
    return type;
}

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

- (void)translate:(NSString *)text from:(nonnull EZLanguage)from to:(nonnull EZLanguage)to completion:(nonnull void (^)(EZQueryResult *, NSError *_Nullable))completion {
    [self bingTranslate:text useDictQuery:[self isEnglishWordToChinese:text from:from to:to] from:from to:to completion:completion];
}

- (BOOL)isEnglishWordToChinese:(NSString *)text from:(nonnull EZLanguage)from to:(nonnull EZLanguage)to {
    if ([from isEqualToString:EZLanguageEnglish] && [to isEqualToString:EZLanguageSimplifiedChinese] && [text shouldQueryDictionaryWithLanguage:from maxWordCount:1]) {
        return YES;
    }
    return NO;
}

- (void)bingTranslate:(NSString *)text useDictQuery:(BOOL)useDictQuery from:(nonnull EZLanguage)from to:(nonnull EZLanguage)to completion:(nonnull void (^)(EZQueryResult *, NSError *_Nullable))completion {
    if ([self prehandleQueryTextLanguage:text from:from to:to completion:completion]) {
        return;
    }
    
    self.isDictQueryResult = NO;
    if (useDictQuery) {
        [self.request translateTextFromDict:text completion:^(NSDictionary * _Nullable json, NSError * _Nullable error) {
            [self parseBingDictTranslate:json word:text completion:^(EZQueryResult *dictResult, NSError * _Nullable dictError) {
                if (error) {
                    [self bingTranslate:text useDictQuery:NO from:from to:to completion:completion];
                } else {
                    self.isDictQueryResult = YES;
                    completion(dictResult, nil);
                }
            }];
        }];
        return;
    }
    
    text = [self maxTextLength:text fromLanguage:from];
    NSString *fromCode = [self languageCodeForLanguage:from];
    NSString *toCode = [self languageCodeForLanguage:to];
    mm_weakify(self)
    [self.request translateText:text from:fromCode to:toCode completionHandler:^(NSData *_Nullable translateData, NSData *_Nullable lookupData, NSError *_Nullable translateError, NSError *_Nullable lookupError) {
        mm_strongify(self)
        @try {
            if (translateError) {
                self.result.error = [EZError errorWithNSError:translateError];
                NSLog(@"bing translate error %@", translateError);
            } else {
                BOOL needRetry;
                NSError *error = [self processTranslateResult:translateData text:text from:from to:to needRetry:&needRetry];
                // canRetry用来避免递归调用，code205只主动重试一次。
                if (self.canRetry && needRetry) {
                    self.canRetry = NO;
                    [self translate:text from:from to:to completion:completion];
                    return;
                }
                self.canRetry = YES;
                if (error) {
                    self.result.error = [EZError errorWithNSError:error];
                    completion(self.result, error);
                    return;
                }
                if (lookupError) {
                    NSLog(@"bing lookup error %@", lookupError);
                } else {
                    [self processWordSimpleWordAndPart:lookupData];
                }
            }
            completion(self.result, translateError);
        } @catch (NSException *exception) {
            MMLogInfo(@"微软翻译接口数据解析异常 %@", exception);
            completion(self.result, [EZError errorWithType:EZErrorTypeAPI description:@"bing translate data parse failed" request:nil]);
        }
    }];
}
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    EZLanguage textLanguage = queryModel.queryFromLanguage;
    
    NSString *from = [self languageCodeForLanguage:textLanguage];
    NSString *to = [self languageCodeForLanguage:queryModel.queryTargetLanguage];
    NSString *maxText = [self maxTextLength:queryModel.queryText fromLanguage:textLanguage];
    
    NSString *text = maxText;
    
    // If Chinese text too long, web link page will report error.
    if ([EZLanguageManager.shared isChineseLanguage:textLanguage]) {
        text = [maxText trimToMaxLength:450];
    }
    
    if (self.isDictQueryResult) {
        return [NSString stringWithFormat:@"https://%@/dict/search?q=%@", self.request.bingConfig.host, text.encode];
    }
    
    return [NSString stringWithFormat:@"%@/?text=%@&from=%@&to=%@", self.request.bingConfig.translatorURLString, text.encode, from, to];
}

- (NSString *)name {
    return NSLocalizedString(@"bing_translate", nil);
}

- (EZServiceType)serviceType {
    return EZServiceTypeBing;
}

- (void)textToAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if ([from isEqualToString:EZLanguageClassicalChinese]) {
        from = EZLanguageSimplifiedChinese;
    }
    
    NSString *filePath = [self.audioPlayer getWordAudioFilePath:text
                                                       language:from
                                                         accent:nil
                                                    serviceType:self.serviceType];
    
    // If file path already exists.
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        completion(filePath, nil);
        return;
    }
    
    NSLog(@"Bing is fetching text audio: %@", text);
    
    [self.request fetchTextToAudio:text fromLanguage:from completion:^(NSData *audioData, NSError *_Nullable error) {
        if (error || !audioData) {
            completion(nil, error);
            return;
        }
        
        [audioData writeToFile:filePath atomically:YES];
        
        completion(filePath, nil);
    }];
}

#pragma mark - private
- (NSString *)maxTextLength:(NSString *)text fromLanguage:(EZLanguage)from {
    if (text.length > 1000) {
        return [text substringToIndex:1000];
    }
    return text;
}

- (nullable NSError *)processTranslateResult:(NSData *)translateData text:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to needRetry:(BOOL *)needRetry {
    if (translateData.length == 0) {
        return [EZError errorWithType:EZErrorTypeAPI description:@"bing translate data is empty" request:nil];
    }
    NSArray *json = [NSJSONSerialization JSONObjectWithData:translateData options:0 error:nil];
    if (![json isKindOfClass:[NSArray class]]) {
        NSString *msg = [NSString stringWithFormat:@"bing json parse failed\n%@", json];
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
        return [EZError errorWithType:EZErrorTypeAPI description:msg request:nil];
    }
    EZBingTranslateModel *translateModel = [EZBingTranslateModel mj_objectArrayWithKeyValuesArray:json].firstObject;
    self.result.from = translateModel.detectedLanguage.language ? [self languageEnumFromCode:translateModel.detectedLanguage.language] : from;
    self.result.to = translateModel.translations.firstObject.to ? [self languageEnumFromCode:translateModel.translations.firstObject.to] : to;
    
    // phonetic
    if (json.count >= 2 && [json[1] isKindOfClass:[NSDictionary class]]) {
        NSString *inputTransliteration = json[1][@"inputTransliteration"];
        EZWordPhonetic *phonetic = [EZWordPhonetic new];
        
        EZLanguage fromLanguage = self.result.queryFromLanguage;
        phonetic.name = [fromLanguage isEqualToString:EZLanguageEnglish] ? NSLocalizedString(@"us_phonetic", nil) : NSLocalizedString(@"chinese_phonetic", nil);
        
        // If text is too long, we don't show phonetic.
        if (![EZLanguageManager.shared isShortWordLength:text language:fromLanguage]) {
            goto outer;
        }
        
        phonetic.value = inputTransliteration;
        // https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/language-support?tabs=tts#supported-languages
        //        phonetic.speakURL = result.fromSpeakURL;
        phonetic.language = fromLanguage;
        phonetic.word = text;
        
        if (!self.result.wordResult) {
            self.result.wordResult = [EZTranslateWordResult new];
        }
        self.result.wordResult.phonetics = @[ phonetic ];
    }
    
outer:
    self.result.raw = translateData;
    self.result.translatedResults = [translateModel.translations mm_map:^id _Nullable(EZBingTranslationsModel *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        return obj.text;
    }];
    return nil;
}

- (void)processWordSimpleWordAndPart:(NSData *)lookupData {
    if (!lookupData) {
        return;
    }
    NSArray *lookupJson = [NSJSONSerialization JSONObjectWithData:lookupData options:0 error:nil];
    if ([lookupJson isKindOfClass:[NSArray class]]) {
        EZBingLookupModel *lookupModel = [EZBingLookupModel mj_objectArrayWithKeyValuesArray:lookupJson].firstObject;
        EZTranslateWordResult *wordResult = self.result.wordResult ?: [EZTranslateWordResult new];
        NSMutableDictionary<NSString *, NSMutableArray<EZBingLookupTranslationsModel *> *> *tags = [NSMutableDictionary dictionary];
        for (EZBingLookupTranslationsModel *translation in lookupModel.translations) {
            NSMutableArray<EZBingLookupTranslationsModel *> *array = tags[translation.posTag];
            if (!array) {
                array = [NSMutableArray array];
                tags[translation.posTag] = array;
            }
            [array addObject:translation];
        }
        
        // 中文翻译英文
        if (([self.result.from isEqualToString:EZLanguageSimplifiedChinese] || [self.result.from isEqualToString:EZLanguageTraditionalChinese]) && [self.result.to isEqualToString:EZLanguageEnglish]) {
            NSMutableArray<EZTranslateSimpleWord *> *simpleWords = [NSMutableArray array];
            [tags enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSMutableArray<EZBingLookupTranslationsModel *> *_Nonnull obj, BOOL *_Nonnull stop) {
                for (EZBingLookupTranslationsModel *model in obj) {
                    EZTranslateSimpleWord *simpleWord = [EZTranslateSimpleWord new];
                    simpleWord.part = [key lowercaseString];
                    simpleWord.word = model.displayTarget;
                    simpleWord.means = [model.backTranslations mm_map:^id _Nullable(EZBingLookupBackTranslationsModel *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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
            [tags enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSMutableArray<EZBingLookupTranslationsModel *> *_Nonnull obj, BOOL *_Nonnull stop) {
                EZTranslatePart *part = [EZTranslatePart new];
                part.part = [key lowercaseString];
                part.means = [obj mm_map:^id _Nullable(EZBingLookupTranslationsModel *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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

- (void)parseBingDictTranslate:(NSDictionary *)json word:(NSString *)word completion:(nonnull void (^)(EZQueryResult *, NSError *_Nullable))completion {
    @try {
        NSArray *value = json[@"value"];
        if (value.count == 0) {
            completion(self.result, [EZError errorWithType:EZErrorTypeAPI description:@"bing dict value is empty" request:nil]);
            return;
        }
        NSArray *meaningGroups = value.firstObject[@"meaningGroups"];
        if (meaningGroups.count == 0) {
            completion(self.result, [EZError errorWithType:EZErrorTypeAPI description:@"bing dict translate meaning groups is empty" request:nil]);
            return;
        }
        
        NSMutableArray<EZTranslatePart *> *parts = [NSMutableArray array];
        NSMutableArray<EZTranslateExchange *> *exchanges = [NSMutableArray array];
        NSMutableArray<EZTranslateSimpleWord *> *simpleWords = [NSMutableArray array];
        NSMutableArray<EZWordPhonetic *> *phonetics = [NSMutableArray array];
        NSMutableArray<EZTranslatePart *> *synonyms = [NSMutableArray array];
        NSMutableArray<EZTranslatePart *> *antonyms = [NSMutableArray array];
        NSMutableArray<EZTranslatePart *> *collocation = [NSMutableArray array];
        
        for (NSDictionary *meaningGroup in meaningGroups) {
            NSArray *partOfSpeech = meaningGroup[@"partsOfSpeech"];
            if (partOfSpeech.count == 0) {
                continue;
            }
            NSString *name = partOfSpeech.firstObject[@"name"];
            NSString *description = partOfSpeech.firstObject[@"description"];
            NSArray *meanings = meaningGroup[@"meanings"];
            if (meanings.count == 0) {
                continue;
            }
            NSArray *richDefinitions = meanings.firstObject[@"richDefinitions"];
            NSArray *fragments = richDefinitions.firstObject[@"fragments"];
            if ([description isEqualToString:@"发音"]) {
                if ([name isEqualToString:@"US"] || [name isEqualToString:@"UK"]) {
                    NSString *usAudioUrl = value.firstObject[@"pronunciationAudio"][@"contentUrl"];
                    EZWordPhonetic *phonetic = [EZWordPhonetic new];
                    phonetic.word = word;
                    phonetic.language = EZLanguageEnglish;
                    phonetic.name = [name isEqualToString:@"US"] ? NSLocalizedString(@"us_phonetic", nil) : NSLocalizedString(@"uk_phonetic", nil);
                    phonetic.value = fragments.firstObject[@"text"];
                    phonetic.speakURL = [name isEqualToString:@"US"] ? usAudioUrl : [usAudioUrl stringByReplacingOccurrencesOfString:@"tom" withString:@"george"];
                    phonetic.accent = name;
                    [phonetics addObject:phonetic];
                }
            } else if ([description isEqualToString:@"快速释义"]) {
                EZTranslatePart *partObj = [EZTranslatePart new];
                partObj.part = name;
                partObj.means = [fragments mm_map:^id _Nullable(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    return obj[@"text"];
                }];
                [parts addObject:partObj];
            } else if ([description isEqualToString:@"词组"]) {
                for (NSDictionary *richDefinition in richDefinitions) {
                    NSArray *examples = richDefinition[@"examples"];
                    if (examples.count != 2) {
                        continue;
                    }
                    EZTranslateSimpleWord *simpleWord = [EZTranslateSimpleWord new];
                    simpleWord.word = examples.firstObject;
                    simpleWord.meansText = examples.lastObject;
                    [simpleWords addObject:simpleWord];
                }
            } else if ([description isEqualToString:@"分类词典"]) {
                NSArray<NSString *> *synonymMeans = [meanings.firstObject[@"synonyms"] mm_map:^id _Nullable(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    return obj[@"name"];
                }];
                NSArray<NSString *> *antonymMeans = [meanings.firstObject[@"antonyms"] mm_map:^id _Nullable(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    return obj[@"name"];
                }];
                
                if (synonymMeans.count) {
                    EZTranslatePart *synonymsPart = [EZTranslatePart new];
                    synonymsPart.part = name;
                    synonymsPart.means = synonymMeans;
                    [synonyms addObject:synonymsPart];
                }
                
                if (antonymMeans.count) {
                    EZTranslatePart *antonymsPart = [EZTranslatePart new];
                    antonymsPart.part = name;
                    antonymsPart.means = antonymMeans;
                    [antonyms addObject:antonymsPart];
                }
            } else if ([description isEqualToString:@"搭配"]) {
                NSArray *means = [fragments mm_map:^id _Nullable(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    return obj[@"text"];
                }];
                EZTranslatePart *collocationPart = [EZTranslatePart new];
                collocationPart.part = name;
                collocationPart.means = means;
                [collocation addObject:collocationPart];
            }
            
            if ([name isEqualToString:@"变形"]) {
                for (NSDictionary *fragment in fragments) {
                    NSString *text = fragment[@"text"];
                    NSArray *value = [text componentsSeparatedByString:@"："];
                    if (value.count == 2) {
                        EZTranslateExchange *exchange = [EZTranslateExchange new];
                        exchange.name = value.firstObject;
                        exchange.words = @[value.lastObject];
                        [exchanges addObject:exchange];
                    }
                }
            }
        }
        
        EZTranslateWordResult *wordResult = [EZTranslateWordResult new];
        self.result.wordResult = wordResult;
        if (phonetics.count) {
            wordResult.phonetics = phonetics;
        }
        if (parts.count) {
            wordResult.parts = parts;
        }
        if (exchanges.count) {
            wordResult.exchanges = exchanges;
        }
        if (simpleWords.count) {
            wordResult.simpleWords = simpleWords;
        }
        if (synonyms.count) {
            wordResult.synonyms = synonyms;
        }
        if (antonyms.count) {
            wordResult.antonyms = antonyms;
        }
        if (collocation.count) {
            wordResult.collocation = collocation;
        }
        self.result.from = EZLanguageEnglish;
        self.result.to = EZLanguageSimplifiedChinese;
        
        // 接口没有字段表示翻译结果，从parts里去一个当作结果。
        NSString *translateResult = wordResult.parts.firstObject.means.firstObject;
        if (translateResult.length) {
            self.result.translatedResults = @[translateResult];
        }
        self.result.raw = json;
        completion(self.result, nil);
    } @catch (NSException *exception) {
        MMLogInfo(@"微软词典接口数据解析异常 %@", exception);
        completion(self.result, [EZError errorWithType:EZErrorTypeAPI description:@"bing dict translate data parse failed" request:nil]);
    }
}

@end
