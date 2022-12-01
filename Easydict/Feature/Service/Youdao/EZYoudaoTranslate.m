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

- (NSString *)identifier {
    return @"Youdao";
}

- (NSString *)name {
    return @"有道翻译";
}

- (NSString *)link {
    return @"http://fanyi.youdao.com";
}

//- (MMOrderedDictionary *)supportLanguagesDictionary {
//    return [[MMOrderedDictionary alloc] initWithKeysAndObjects:
//            @(EZEZLanguageAuto), @"auto", @(EZEZLanguageSimplifiedChinese), @"zh-CHS", @(EZEZLanguageEnglish), @"en", @(EZLanguage_yue), @"yue", @(EZLanguage_ja), @"ja", @(EZLanguage_ko), @"ko", @(EZLanguage_fr), @"fr", @(EZLanguage_es), @"es", @(EZLanguage_pt), @"pt", @(EZLanguage_it), @"it", @(EZLanguage_ru), @"ru", @(EZLanguage_vi), @"vi", @(EZLanguage_de), @"de", @(EZLanguage_ar), @"ar", @(EZLanguage_id), @"id", @(EZLanguage_af), @"af", @(EZLanguage_bs), @"bs", @(EZLanguage_bg), @"bg", @(EZLanguage_ca), @"ca", @(EZLanguage_hr), @"hr", @(EZLanguage_cs), @"cs", @(EZLanguage_da), @"da", @(EZLanguage_nl), @"nl", @(EZLanguage_et), @"et", @(EZLanguage_fj), @"fj", @(EZLanguage_fi), @"fi", @(EZLanguage_el), @"el", @(EZLanguage_ht), @"ht", @(EZLanguage_he), @"he", @(EZLanguage_hi), @"hi", @(EZLanguage_mww), @"mww", @(EZLanguage_hu), @"hu", @(EZLanguage_sw), @"sw", @(EZLanguage_tlh), @"tlh", @(EZLanguage_lv), @"lv", @(EZLanguage_lt), @"lt", @(EZLanguage_ms), @"ms", @(EZLanguage_mt), @"mt", @(EZLanguage_no), @"no", @(EZLanguage_fa), @"fa", @(EZLanguage_pl), @"pl", @(EZLanguage_otq), @"otq", @(EZLanguage_ro), @"ro", @(EZLanguage_sr_Cyrl), @"sr-Cyrl", @(EZLanguage_sr_Latn), @"sr-Latn", @(EZLanguage_sk), @"sk", @(EZLanguage_sv), @"sv", @(EZLanguage_ty), @"ty", @(EZLanguage_th), @"th", @(EZLanguage_to), @"to", @(EZLanguage_tr), @"tr", @(EZLanguage_uk), @"uk", @(EZLanguage_ur), @"ur", @(EZLanguage_cy), @"cy", @(EZLanguage_yua), @"yua", @(EZLanguage_sq), @"sq", @(EZLanguage_am), @"am", @(EZLanguage_hy), @"hy", @(EZLanguage_az), @"az", @(EZLanguage_bn), @"bn", @(EZLanguage_eu), @"eu", @(EZLanguage_be), @"be", @(EZLanguage_ceb), @"ceb", @(EZLanguage_co), @"co", @(EZLanguage_eo), @"eo", @(EZLanguage_tl), @"tl", @(EZLanguage_fy), @"fy", @(EZLanguage_gl), @"gl", @(EZLanguage_ka), @"ka", @(EZLanguage_gu), @"gu", @(EZLanguage_ha), @"ha", @(EZLanguage_haw), @"haw", @(EZLanguage_is), @"is", @(EZLanguage_ig), @"ig", @(EZLanguage_ga), @"ga", @(EZLanguage_jw), @"jw", @(EZLanguage_kn), @"kn", @(EZLanguage_kk), @"kk", @(EZLanguage_km), @"km", @(EZLanguage_ku), @"ku", @(EZLanguage_ky), @"ky", @(EZLanguage_lo), @"lo", @(EZLanguage_la), @"la", @(EZLanguage_lb), @"lb", @(EZLanguage_mk), @"mk", @(EZLanguage_mg), @"mg", @(EZLanguage_mi), @"mi", @(EZLanguage_ml), @"ml", @(EZLanguage_mr), @"mr", @(EZLanguage_mn), @"mn", @(EZLanguage_my), @"my", @(EZLanguage_ne), @"ne", @(EZLanguage_ny), @"ny", @(EZLanguage_ps), @"ps", @(EZLanguage_pa), @"pa", @(EZLanguage_sm), @"sm", @(EZLanguage_gd), @"gd", @(EZLanguage_st), @"st", @(EZLanguage_sn), @"sn", @(EZLanguage_sd), @"sd", @(EZLanguage_si), @"si", @(EZLanguage_so), @"so", @(EZLanguage_su), @"su", @(EZLanguage_tg), @"tg", @(EZLanguage_ta), @"ta", @(EZLanguage_te), @"te", @(EZLanguage_uz), @"uz", @(EZLanguage_xh), @"xh", @(EZLanguage_yi), @"yi", @(EZLanguage_yo), @"yo", @(EZLanguage_zu), @"zu", nil];
//}


// Currently supports 48 languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, Spanish, Portuguese, Italian, German, Russian, Arabic, Swedish, Romanian, Thai, Slovak, Dutch, Hungarian, Greek, Danish, Finnish, Polish, Czech, Turkish, Lithuanian, Latvian, Ukrainian, Bulgarian, Indonesian, Malay, Slovenian, Estonian, Vietnamese, Persian, Hindi, Telugu, Tamil, Urdu, Filipino, Khmer, Lao, Bengali, Burmese, Norwegian, Serbian, Croatian, Mongolian, Hebrew.

// get supportLanguagesDictionary, key is EZLanguage, value is NLLanguage, such as EZLanguageAuto, NLLanguageUndetermined
- (MMOrderedDictionary *)supportLanguagesDictionary {
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
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    NSString *url = @"https://aidemo.youdao.com/trans";
    NSDictionary *params = @{
        @"from" : [self languageStringFromEnum:from],
        @"to" : [self languageStringFromEnum:to],
        @"q" : text,
    };
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params, EZTranslateErrorRequestParamKey, nil];
    
    mm_weakify(self);
    [self.jsonSession POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        mm_strongify(self);
        NSString *message = nil;
        if (responseObject) {
            @try {
                YoudaoTranslateResponse *response = [YoudaoTranslateResponse mj_objectWithKeyValues:responseObject];
                if (response && response.errorCode.integerValue == 0) {
                    EZQueryResult *result = [EZQueryResult new];
                    self.result = result;
                    
                    result.text = text;
                    result.fromSpeakURL = response.speakUrl;
                    result.toSpeakURL = response.tSpeakUrl;
                    
                    // 解析语言
                    NSArray *languageComponents = [response.l componentsSeparatedByString:@"2"];
                    if (languageComponents.count == 2) {
                        result.from = [self languageEnumFromString:languageComponents.firstObject];
                        result.to = [self languageEnumFromString:languageComponents.lastObject];
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
                        } else if (result.from == EZLanguageSimplifiedChinese && result.to == EZLanguageEnglish) {
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
                            if (result.from == EZLanguageEnglish &&
                                result.to == EZLanguageSimplifiedChinese &&
                                wordResult.phonetics.firstObject.speakURL.length) {
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
                    
                    // 生成网页链接
                    if (result.wordResult) {
                        result.link = [NSString stringWithFormat:@"https://dict.youdao.com/search?q=%@&keyfrom=fanyi.smartResult", text.mm_urlencode];
                    } else {
                        // TODO: 句子翻译跳转貌似不行了
                        result.link = [NSString stringWithFormat:@"http://fanyi.youdao.com/translate?i=%@", text.mm_urlencode];
                    }
                    
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
        completion(nil, EZTranslateError(EZTranslateErrorTypeAPI, message ?: @"翻译失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, EZTranslateError(EZTranslateErrorTypeNetwork, @"翻译失败", reqDict));
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
                    result.from = [self languageEnumFromString:response.lanFrom];
                    result.to = [self languageEnumFromString:response.lanTo];
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
            if (to == EZLanguageAuto || to == EZOCRResult.to) {
                if (!((EZOCRResult.to == EZLanguageSimplifiedChinese || EZOCRResult.to == EZLanguageEnglish) &&
                      ![EZOCRResult.mergedText containsString:@" "])) {
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
