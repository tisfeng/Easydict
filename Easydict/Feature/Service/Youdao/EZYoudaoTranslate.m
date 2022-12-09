//
//  EZYoudaoTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZYoudaoTranslate.h"
#import "YoudaoTranslateResponse.h"
#import "YoudaoOCRResponse.h"

static NSString *const kYoudaoTranslateURL = @"https://www.youdao.com";

@interface EZYoudaoTranslate ()

@property (nonatomic, strong) AFHTTPSessionManager *jsonSession;

@end


@implementation EZYoudaoTranslate

- (AFHTTPSessionManager *)jsonSession {
    if (!_jsonSession) {
        AFHTTPSessionManager *jsonSession = [AFHTTPSessionManager manager];
        
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        jsonSession.requestSerializer = requestSerializer;
        
        AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", nil];
        jsonSession.responseSerializer = responseSerializer;
        
        _jsonSession = jsonSession;
    }
    return _jsonSession;
}

#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeYoudao;
}

- (NSString *)name {
    return @"有道翻译";
}

- (NSString *)link {
    return @"http://fanyi.youdao.com";
}

// https://www.youdao.com/result?word=good&lang=en
// youdao support 4 languages: en, ja, ko, fr, and to Chinese
// means: en <-> zh-CHS, ja <-> zh-CHS, ko <-> zh-CHS, fr <-> zh-CHS, if language not in this list, then return nil.
- (NSString *)wordLink {
    EZLanguage fromLanguage = self.queryModel.queryFromLanguage;
    EZLanguage toLanguage = self.queryModel.autoTargetLanguage;
    
    NSString *youdaoFrom = [self languageCodeForLanguage:self.queryModel.queryFromLanguage];
    NSString *youdaoTo = [self languageCodeForLanguage:self.queryModel.autoTargetLanguage];
    NSString *encodedWord = [self.queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSArray *youdaoLanguags = @[ EZLanguageEnglish, EZLanguageJapanese, EZLanguageFrench, EZLanguageKorean ];
    NSMutableArray *youdaoLanguageCodes = [NSMutableArray array];
    for (EZLanguage langauge in youdaoLanguags) {
        NSString *code = [self languageCodeForLanguage:langauge];
        [youdaoLanguageCodes addObject:code];
    }
    
    if (![EZLanguageManager isChineseLanguage:fromLanguage] && ![EZLanguageManager isChineseLanguage:toLanguage]) {
        return nil;
    }
    
    NSString *foreignLangauge = youdaoTo;
    if ([youdaoLanguageCodes containsObject:youdaoFrom]) {
        foreignLangauge = youdaoFrom;
    }
    
    return [NSString stringWithFormat:@"%@/result?word=%@&lang=%@", kYoudaoTranslateURL, encodedWord, foreignLangauge];
}


- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, @"auto",
                                        EZLanguageSimplifiedChinese, @"zh-CHS",
                                        EZLanguageTraditionalChinese, @"zh-CHT",
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
                                        EZLanguageFilipino, @"tl",
                                        EZLanguageKhmer, @"km",
                                        EZLanguageLao, @"lo",
                                        EZLanguageBengali, @"bn",
                                        EZLanguageNorwegian, @"no",
                                        EZLanguageSerbian, @"sr",
                                        EZLanguageCroatian, @"hr",
                                        EZLanguageMongolian, @"mn",
                                        EZLanguageHebrew, @"iw",
                                        nil];
    return orderedDict;
}


- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    if (!text.length) {
        completion(self.result, EZTranslateError(EZTranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    NSString *url = @"https://aidemo.youdao.com/trans";
    NSDictionary *params = @{
        @"from" : [self languageCodeForLanguage:from],
        @"to" : [self languageCodeForLanguage:to],
        @"q" : text,
    };
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params, EZTranslateErrorRequestParamKey, nil];
    
    EZQueryResult *result = self.result;
    
    mm_weakify(self);
    [self.jsonSession POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        mm_strongify(self);
        NSString *message = nil;
        if (responseObject) {
            @try {
                YoudaoTranslateResponse *response = [YoudaoTranslateResponse mj_objectWithKeyValues:responseObject];
                if (response && response.errorCode.integerValue == 0) {
                    
                    result.text = text;
                    result.fromSpeakURL = response.speakUrl;
                    result.toSpeakURL = response.tSpeakUrl;
                    
                    // 解析语言
                    NSArray *languageComponents = [response.l componentsSeparatedByString:@"2"];
                    if (languageComponents.count == 2) {
                        result.from = [self languageEnumFromCode:languageComponents.firstObject];
                        result.to = [self languageEnumFromCode:languageComponents.lastObject];
                    } else {
                        MMAssert(0, @"有道翻译语种解析失败 %@", responseObject);
                    }
                    
                    // 中文查词 英文查词
                    YoudaoTranslateResponseBasic *basic = response.basic;
                    if (basic) {
                        EZTranslateWordResult *wordResult = [EZTranslateWordResult new];
                        
                        // 解析音频
                        NSMutableArray *phoneticArray = [NSMutableArray array];
                        if (basic.us_phonetic && basic.us_speech) {
                            EZTranslatePhonetic *phonetic = [EZTranslatePhonetic new];
                            phonetic.name = @"美";
                            phonetic.value = basic.us_phonetic;
                            phonetic.speakURL = basic.us_speech;
                            [phoneticArray addObject:phonetic];
                        }
                        if (basic.uk_phonetic && basic.uk_speech) {
                            EZTranslatePhonetic *phonetic = [EZTranslatePhonetic new];
                            phonetic.name = @"英";
                            phonetic.value = basic.uk_phonetic;
                            phonetic.speakURL = basic.uk_speech;
                            [phoneticArray addObject:phonetic];
                        }
                        if (phoneticArray.count) {
                            wordResult.phonetics = phoneticArray.copy;
                        }
                        
                        // 解析词性词义
                        if (wordResult.phonetics) {
                            // 英文查词
                            NSMutableArray *partArray = [NSMutableArray array];
                            [basic.explains enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                if (![obj isKindOfClass:NSString.class]) {
                                    return;
                                }
                                EZTranslatePart *part = [EZTranslatePart new];
                                part.means = @[ obj ];
                                [partArray addObject:part];
                            }];
                            if (partArray.count) {
                                wordResult.parts = partArray.copy;
                            }
                        } else if ([result.from isEqualToString:EZLanguageSimplifiedChinese]
                                   && [result.to isEqualToString:EZLanguageEnglish]) {
                            // 中文查词
                            NSMutableArray *simpleWordArray = [NSMutableArray array];
                            [basic.explains enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                if ([obj isKindOfClass:NSString.class]) {
                                    if ([obj containsString:@";"]) {
                                        // 拆分成多个
                                        MMLogInfo(@"有道翻译手动拆词 %@", obj);
                                        NSArray<NSString *> *words = [obj componentsSeparatedByString:@";"];
                                        [words enumerateObjectsUsingBlock:^(NSString *_Nonnull subObj, NSUInteger idx, BOOL *_Nonnull stop) {
                                            EZTranslateSimpleWord *word = [EZTranslateSimpleWord new];
                                            word.word = subObj;
                                            [simpleWordArray addObject:word];
                                        }];
                                    } else {
                                        EZTranslateSimpleWord *word = [EZTranslateSimpleWord new];
                                        word.word = obj;
                                        [simpleWordArray addObject:word];
                                    }
                                } else if ([obj isKindOfClass:NSDictionary.class]) {
                                    // 20191226 突然变成了字典结构，应该是改 API 了
                                    NSDictionary *dict = (NSDictionary *)obj;
                                    NSString *text = [dict objectForKey:@"text"];
                                    NSString *tran = [dict objectForKey:@"tran"];
                                    if ([text isKindOfClass:NSString.class] && text.length) {
                                        if ([text containsString:@";"]) {
                                            // 拆分成多个 测试中
                                            MMLogInfo(@"有道翻译手动拆词 %@", text);
                                            NSArray<NSString *> *words = [text componentsSeparatedByString:@";"];
                                            [words enumerateObjectsUsingBlock:^(NSString *_Nonnull subObj, NSUInteger idx, BOOL *_Nonnull stop) {
                                                EZTranslateSimpleWord *word = [EZTranslateSimpleWord new];
                                                word.word = subObj;
                                                [simpleWordArray addObject:word];
                                            }];
                                        } else {
                                            EZTranslateSimpleWord *word = [EZTranslateSimpleWord new];
                                            word.word = text;
                                            if ([tran isKindOfClass:NSString.class] && tran.length) {
                                                word.means = @[ tran ];
                                            }
                                            [simpleWordArray addObject:word];
                                        }
                                    }
                                }
                            }];
                            if (simpleWordArray.count) {
                                wordResult.simpleWords = simpleWordArray;
                            }
                        }
                        
                        // 至少要有词义或单词组才认为有单词翻译结果
                        if (wordResult.parts || wordResult.simpleWords) {
                            result.wordResult = wordResult;
                            // 如果是单词或短语，优先使用美式发音
                            if ([result.from isEqualToString:EZLanguageEnglish]
                                && [result.to isEqualToString:EZLanguageSimplifiedChinese]
                                && wordResult.phonetics.firstObject.speakURL.length) {
                                result.fromSpeakURL = wordResult.phonetics.firstObject.speakURL;
                            }
                        }
                    }
                    
                    // 解析普通释义
                    NSMutableArray *normalResults = [NSMutableArray array];
                    [response.translation enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                        [normalResults addObject:obj];
                    }];
                    result.normalResults = normalResults.count ? normalResults.copy : nil;
                    
                    // 原始数据
                    result.raw = responseObject;
                    
                    if (result.wordResult || result.normalResults) {
                        completion(result, nil);
                        return;
                    }
                } else {
                    message = [NSString stringWithFormat:@"翻译失败，错误码 %@", response.errorCode];
                }
            } @catch (NSException *exception) {
                MMLogInfo(@"有道翻译翻译接口数据解析异常 %@", exception);
                message = @"有道翻译翻译接口数据解析异常";
            }
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        completion(self.result, EZTranslateError(EZTranslateErrorTypeAPI, message ?: @"翻译失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(self.result, EZTranslateError(EZTranslateErrorTypeNetwork, @"翻译失败", reqDict));
    }];
}

- (void)detect:(NSString *)text completion:(void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto, EZTranslateError(EZTranslateErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }
    
    // 字符串太长浪费时间，截取了前面一部分。为什么是73？百度取的73，这里抄了一下...
    NSString *queryString = text;
    if (queryString.length >= 73) {
        queryString = [queryString substringToIndex:73];
    }
    
    [self translate:queryString from:EZLanguageAuto to:EZLanguageAuto completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
        if (result) {
            completion(result.from, nil);
        } else {
            completion(EZLanguageAuto, error);
        }
    }];
}

- (void)audio:(NSString *)text from:(EZLanguage)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }
    
    [self translate:text from:from to:EZLanguageAuto completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
        if (result) {
            if (result.fromSpeakURL.length) {
                completion(result.fromSpeakURL, nil);
            } else {
                NSDictionary *params = @{
                    EZTranslateErrorRequestParamKey : @{
                        @"text" : text ?: @"",
                        @"from" : from,
                    },
                };
                completion(nil, EZTranslateError(EZTranslateErrorTypeUnsupportLanguage, @"有道翻译不支持获取该语言音频", params));
            }
        } else {
            completion(nil, error);
        }
    }];
}

- (void)ocr:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZOCRResult *_Nullable result, NSError *_Nullable error))completion {
    if (!image) {
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    
    NSData *data = [image mm_PNGData];
    NSString *encodedImageStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    encodedImageStr = [NSString stringWithFormat:@"data:image/png;base64,%@", encodedImageStr];
    
    // 目前没法指定图片翻译的目标语言
    NSString *url = @"https://aidemo.youdao.com/ocrtransapi1";
    NSDictionary *params = @{
        @"imgBase" : encodedImageStr,
    };
    // 图片 base64 字符串过长，暂不打印
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, nil];
    
    mm_weakify(self);
    [self.jsonSession POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        mm_strongify(self);
        NSString *message = nil;
        if (responseObject) {
            @try {
                YoudaoOCRResponse *response = [YoudaoOCRResponse mj_objectWithKeyValues:responseObject];
                if (response) {
                    EZOCRResult *result = [EZOCRResult new];
                    result.from = [self languageEnumFromCode:response.lanFrom];
                    result.to = [self languageEnumFromCode:response.lanTo];
                    result.ocrTextArray = [response.lines mm_map:^id _Nullable(YoudaoOCRResponseLine *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                        EZOCRText *text = [EZOCRText new];
                        text.text = obj.context;
                        text.translatedText = obj.tranContent;
                        return text;
                    }];
                    result.raw = responseObject;
                    if (result.ocrTextArray.count) {
                        // 有道翻译自动分段，会将分布在几行的句子合并，故用换行分割
                        result.mergedText = [NSString mm_stringByCombineComponents:[result.ocrTextArray mm_map:^id _Nullable(EZOCRText *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            return obj.text;
                        }] separatedString:@"\n"];
                        completion(result, nil);
                        return;
                    }
                }
            } @catch (NSException *exception) {
                MMLogInfo(@"有道翻译OCR接口数据解析异常 %@", exception);
                message = @"有道翻译OCR接口数据解析异常";
            }
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        completion(nil, EZTranslateError(EZTranslateErrorTypeAPI, message ?: @"图片翻译失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, EZTranslateError(EZTranslateErrorTypeNetwork, @"图片翻译失败", reqDict));
    }];
}

- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable, EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, nil, EZTranslateError(EZTranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    
    mm_weakify(self);
    [self ocr:image from:from to:to completion:^(EZOCRResult *_Nullable EZOCRResult, NSError *_Nullable error) {
        mm_strongify(self);
        if (EZOCRResult) {
            // 如果翻译结果的语种匹配，不是中文查词或者英文查词时，不调用翻译接口
            if ([to isEqualToString:EZLanguageAuto] || [to isEqualToString:EZOCRResult.to]) {
                if (!(([EZOCRResult.to isEqualToString:EZLanguageSimplifiedChinese]
                       || [EZOCRResult.to isEqualToString:EZLanguageEnglish])
                      && ![EZOCRResult.mergedText containsString:@" "])) {
                    // 直接回调翻译结果
                    NSLog(@"直接输出翻译结果");
                    ocrSuccess(EZOCRResult, NO);
                    EZQueryResult *result = [EZQueryResult new];
                    result.text = EZOCRResult.mergedText;
                    result.link = [NSString stringWithFormat:@"http://fanyi.youdao.com/translate?i=%@", EZOCRResult.mergedText.mm_urlencode];
                    result.from = EZOCRResult.from;
                    result.to = EZOCRResult.to;
                    result.normalResults = [EZOCRResult.ocrTextArray mm_map:^id _Nullable(EZOCRText *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                        return obj.translatedText;
                    }];
                    result.raw = EZOCRResult.raw;
                    completion(EZOCRResult, result, nil);
                    return;
                }
            }
            ocrSuccess(EZOCRResult, YES);
            [self translate:EZOCRResult.mergedText from:from to:to completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
                completion(EZOCRResult, result, error);
            }];
        } else {
            completion(nil, nil, error);
        }
    }];
}

@end
