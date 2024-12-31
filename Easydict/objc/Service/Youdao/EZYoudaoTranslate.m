//
//  EZYoudaoTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZYoudaoTranslate.h"
#import "EZYoudaoTranslateResponse.h"
#import "EZYoudaoOCRResponse.h"
#import "EZYoudaoDictModel.h"
#import "EZQueryResult+EZYoudaoDictModel.h"
#import "NSString+EZUtils.h"
#import <CommonCrypto/CommonCryptor.h>
#import "NSData+EZMD5.h"
#import "EZNetworkManager.h"
#import "Easydict-Swift.h"

static NSString *const kYoudaoTranslatetURL = @"https://fanyi.youdao.com";
static NSString *const kYoudaoDictURL = @"https://dict.youdao.com";

@interface EZYoudaoTranslate ()

@property (nonatomic, strong) AFHTTPSessionManager *jsonSession;

@property (nonatomic, strong) EZNetworkManager *networkManager;

@property (nonatomic, copy) NSString *cookie;

@end


@implementation EZYoudaoTranslate

- (AFHTTPSessionManager *)jsonSession {
    if (!_jsonSession) {
        AFHTTPSessionManager *jsonSession = [AFHTTPSessionManager manager];
        
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        jsonSession.requestSerializer = requestSerializer;
        
        AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/plain", nil];
        jsonSession.responseSerializer = responseSerializer;
        
        _jsonSession = jsonSession;
    }
    return _jsonSession;
}

- (NSString *)cookie {
    NSString *cookie = [NSUserDefaults mm_read:kYoudaoTranslatetURL];
    if (!cookie) {
        cookie = @"OUTFOX_SEARCH_USER_ID=833782676@113.88.171.235; domain=.youdao.com; expires=2052-12-31 13:12:38 +0000";
        [NSUserDefaults mm_write:cookie forKey:kYoudaoTranslatetURL];
        
        /**
         Youdao's cookie seems to have a long expiration date, so we don't need to update them frequently.
         
         So we only request the cookie the first time we use it, or webTranslate() fails.
         */
        [self requestYoudaoCookie];
    }
    return cookie;
}


#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeYoudao;
}

- (EZQueryTextType)queryTextType {
    EZQueryTextType type = EZQueryTextTypeNone;
    BOOL enableTranslation = [[NSUserDefaults mm_readString:EZYoudaoTranslationKey defaultValue:@"1"] boolValue];
    BOOL enableDictionary = [[NSUserDefaults mm_readString:EZYoudaoDictionaryKey defaultValue:@"1"] boolValue];
    if (enableTranslation) {
        type = type | EZQueryTextTypeTranslation | EZQueryTextTypeSentence;
    }
    if (enableDictionary) {
        type = type | EZQueryTextTypeDictionary;
    }
    
    return type;
}

- (EZQueryTextType)intelligentQueryTextType {
    EZQueryTextType type = [Configuration.shared intelligentQueryTextTypeForServiceType:self.serviceType];
    return type;
}

- (NSString *)name {
    return NSLocalizedString(@"youdao_dict", nil);
}

- (NSString *)link {
    return kYoudaoTranslatetURL;
}

/**
 Youdao word link, support 4 languages: en, ja, ko, fr, and to Chinese. https://www.youdao.com/result?word=good&lang=en
 
 means: en <-> zh-CHS, ja <-> zh-CHS, ko <-> zh-CHS, fr <-> zh-CHS, if language not in this list, then return nil.
 */
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *encodedWord = [queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *foreignLangauge = [self youdaoDictForeignLangauge:queryModel];
    if (!foreignLangauge) {
        return self.link;
    }
    return [NSString stringWithFormat:@"%@/result?word=%@&lang=%@", kYoudaoDictURL, encodedWord, foreignLangauge];
}

- (nullable NSString *)youdaoDictForeignLangauge:(EZQueryModel *)queryModel {
    EZLanguage fromLanguage = queryModel.queryFromLanguage;
    EZLanguage toLanguage = queryModel.queryTargetLanguage;
    
    NSArray *youdaoSupportedLanguags = @[ EZLanguageEnglish, EZLanguageJapanese, EZLanguageFrench, EZLanguageKorean ];
    NSMutableArray *youdaoSupportedLanguageCodes = [NSMutableArray array];
    for (EZLanguage langauge in youdaoSupportedLanguags) {
        NSString *code = [self languageCodeForLanguage:langauge];
        [youdaoSupportedLanguageCodes addObject:code];
    }
    
    NSString *foreignLangauge = nil; // en,fr,
    if ([EZLanguageManager.shared isChineseLanguage:fromLanguage]) {
        foreignLangauge = [self languageCodeForLanguage:toLanguage];
    } else if ([EZLanguageManager.shared isChineseLanguage:toLanguage]) {
        foreignLangauge = [self languageCodeForLanguage:fromLanguage];
    }
    
    if ([youdaoSupportedLanguageCodes containsObject:foreignLangauge]) {
        return foreignLangauge;
    }
    return nil;
}

/**
 Note: The official Youdao API supports most languages, but its web page shows that only 15 languages are supported. https://fanyi.youdao.com/index.html#/
 */
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        //                                        EZLanguageAuto, @"auto",
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
                                        //                                        EZLanguageSwedish, @"sv",
                                        //                                        EZLanguageRomanian, @"ro",
                                        EZLanguageThai, @"th",
                                        //                                        EZLanguageSlovak, @"sk",
                                        EZLanguageDutch, @"nl",
                                        //                                        EZLanguageHungarian, @"hu",
                                        //                                        EZLanguageGreek, @"el",
                                        //                                        EZLanguageDanish, @"da",
                                        //                                        EZLanguageFinnish, @"fi",
                                        //                                        EZLanguagePolish, @"pl",
                                        //                                        EZLanguageCzech, @"cs",
                                        //                                        EZLanguageTurkish, @"tr",
                                        //                                        EZLanguageLithuanian, @"lt",
                                        //                                        EZLanguageLatvian, @"lv",
                                        //                                        EZLanguageUkrainian, @"uk",
                                        //                                        EZLanguageBulgarian, @"bg",
                                        EZLanguageIndonesian, @"id",
                                        //                                        EZLanguageMalay, @"ms",
                                        //                                        EZLanguageSlovenian, @"sl",
                                        //                                        EZLanguageEstonian, @"et",
                                        EZLanguageVietnamese, @"vi",
                                        //                                        EZLanguagePersian, @"fa",
                                        //                                        EZLanguageHindi, @"hi",
                                        //                                        EZLanguageTelugu, @"te",
                                        //                                        EZLanguageTamil, @"ta",
                                        //                                        EZLanguageUrdu, @"ur",
                                        //                                        EZLanguageFilipino, @"tl",
                                        //                                        EZLanguageKhmer, @"km",
                                        //                                        EZLanguageLao, @"lo",
                                        //                                        EZLanguageBengali, @"bn",
                                        //                                        EZLanguageBurmese, @"my",
                                        //                                        EZLanguageNorwegian, @"no",
                                        //                                        EZLanguageSerbian, @"sr",
                                        //                                        EZLanguageCroatian, @"hr",
                                        //                                        EZLanguageMongolian, @"mn",
                                        //                                        EZLanguageHebrew, @"iw",
                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion {
    if (!text.length) {
        completion(self.result, [EZError errorWithType:EZErrorTypeParam description:@"翻译的文本为空" request:nil]);
        return;
    }
    
    [self queryYoudaoDictAndTranslation:text from:from to:to completion:completion];
}

- (void)detectText:(NSString *)text completion:(void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto, [EZError errorWithType:EZErrorTypeParam description:@"识别语言的文本为空" request:nil]);
        return;
    }
    
    // 字符串太长浪费时间，截取了前面一部分。为什么是73？百度取的73，这里抄了一下...
    NSString *queryString = [text trimToMaxLength:73];
    
    [self translate:queryString from:EZLanguageAuto to:EZLanguageAuto completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
        if (result) {
            completion(result.from, nil);
        } else {
            completion(EZLanguageAuto, error);
        }
    }];
}

- (void)textToAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, [EZError errorWithType:EZErrorTypeParam description:@"获取音频的文本为空" request:nil]);
        return;
    }
    
    /**
     It seems that the Youdao TTS audio will auto trim to 600 chars.
     https://dict.youdao.com/dictvoice?audio=Ukraine%20may%20get%20another%20Patriot%20battery.&le=en
     
     Sogou language codes are the same as Youdaos.
     https://fanyi.sogou.com/reventondc/synthesis?text=class&speed=1&lang=enS&from=translateweb&speaker=6
     */
    
    NSString *language = [self getTTSLanguageCode:from];
    
    //    text = [text trimToMaxLength:1000];
    text = [text encode]; // text.mm_urlencode
    
    NSString *audioURL = [NSString stringWithFormat:@"%@/dictvoice?audio=%@&le=%@", kYoudaoDictURL, text, language];
    //    audioURL = [NSString stringWithFormat:@"https://fanyi.sogou.com/reventondc/synthesis?text=%@&speed=1&lang=%@&from=translateweb&speaker=6", text, language];
    
    completion(audioURL, nil);
}

- (void)ocr:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZOCRResult *_Nullable result, NSError *_Nullable error))completion {
    if (!image) {
        completion(nil, [EZError errorWithType:EZErrorTypeParam description:@"图片为空" request:nil]);
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
                EZYoudaoOCRResponse *response = [EZYoudaoOCRResponse mj_objectWithKeyValues:responseObject];
                if (response) {
                    EZOCRResult *result = [EZOCRResult new];
                    result.from = [self languageEnumFromCode:response.lanFrom];
                    result.to = [self languageEnumFromCode:response.lanTo];
                    result.ocrTextArray = [response.lines mm_map:^id _Nullable(EZYoudaoOCRResponseLine *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                        EZOCRText *text = [EZOCRText new];
                        text.text = obj.context;
                        text.translatedText = obj.tranContent;
                        return text;
                    }];
                    result.raw = responseObject;
                    if (result.ocrTextArray.count) {
                        // 有道翻译自动分段，会将分布在几行的句子合并，故用换行分割
                        NSArray<NSString *> *textArray = [result.ocrTextArray mm_map:^id _Nullable(EZOCRText *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            return obj.text;
                        }];
                        
                        result.texts = textArray;
                        result.mergedText = [textArray componentsJoinedByString:@"\n"];
                        
                        completion(result, nil);
                        return;
                    }
                }
            } @catch (NSException *exception) {
                MMLogError(@"有道翻译OCR接口数据解析异常 %@", exception);
                message = @"有道翻译OCR接口数据解析异常";
            }
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        completion(nil, [EZError errorWithType:EZErrorTypeAPI description: message ?: @"图片翻译失败" request:reqDict]);
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, [EZError errorWithType:EZErrorTypeNetwork description:@"图片翻译失败" request:reqDict]);
    }];
}

- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable, EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, nil, [EZError errorWithType:EZErrorTypeParam description:@"图片为空" request:nil]);
        return;
    }
    
    mm_weakify(self);
    [self ocr:image from:from to:to completion:^(EZOCRResult *_Nullable EZOCRResult, NSError *_Nullable error) {
        mm_strongify(self);
        if (EZOCRResult) {
            // 如果翻译结果的语种匹配，不是中文查词或者英文查词时，不调用翻译接口
            if ([to isEqualToString:EZLanguageAuto] || [to isEqualToString:EZOCRResult.to]) {
                if (!(([EZOCRResult.to isEqualToString:EZLanguageSimplifiedChinese] || [EZOCRResult.to isEqualToString:EZLanguageEnglish]) && ![EZOCRResult.mergedText containsString:@" "])) {
                    // 直接回调翻译结果
                    MMLogInfo(@"直接输出翻译结果");
                    ocrSuccess(EZOCRResult, NO);
                    EZQueryResult *result = [EZQueryResult new];
                    result.queryText = EZOCRResult.mergedText;
                    result.from = EZOCRResult.from;
                    result.to = EZOCRResult.to;
                    result.translatedResults = [EZOCRResult.ocrTextArray mm_map:^id _Nullable(EZOCRText *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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

#pragma mark - Youdao Translate

- (void)queryYoudaoDictAndTranslation:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion {
    if (!text.length) {
        completion(self.result, [EZError errorWithType:EZErrorTypeParam description:@"翻译的文本为空" request:nil]);
        return;
    }
    
    if (self.queryTextType == EZQueryTextTypeNone) {
        completion(self.result, [EZError errorWithType:EZErrorTypeNoResultsFound description:nil]);
        return;
    }
    
    
    // 1. Query dict.
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [self queryYoudaoDict:text from:from to:to completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
        if (error) {
            MMLogError(@"queryYoudaoDict error: %@", error);
        }
        dispatch_group_leave(group);
    }];
    
    BOOL enableTranslation = self.queryTextType & EZQueryTextTypeTranslation;
    if (enableTranslation) {
        // 2.Query Youdao translate.
        dispatch_group_enter(group);
        [self webTranslate:text from:from to:to completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
            if (error) {
                MMLogError(@"translateYoudaoAPI error: %@", error);
                self.result.error = [EZError errorWithNSError:error];
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completion(self.result, self.result.error);
    });
}

/// Query Youdao dict, unofficial API
- (void)queryYoudaoDict:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion {
    if (!text.length) {
        completion(self.result, [EZError errorWithType:EZErrorTypeParam description:@"翻译的文本为空" request:nil]);
        return;
    }
    
    if (self.queryTextType == EZQueryTextTypeNone) {
        completion(self.result, nil);
        return;
    }
    
    BOOL enableDictionary = self.queryTextType & EZQueryTextTypeDictionary;
    
    NSString *foreignLangauge = [self youdaoDictForeignLangauge:self.queryModel];
    BOOL supportQueryDictionaryLanguage = foreignLangauge != nil;
    
    // If Youdao Dictionary does not support the language, try querying translate API.
    if (!enableDictionary || !supportQueryDictionaryLanguage) {
        completion(self.result, [EZError errorWithType:EZErrorTypeNoResultsFound]);
        return;
    }
    
    
    // Query dict.
    NSArray *dictArray = @[ @[ @"web_trans", @"ec", @"ce", @"newhh", @"baike", @"wikipedia_digest" ] ];
    NSDictionary *dicts = @{
        @"count" : @(99),
        @"dicts" : dictArray,
    };
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dicts options:0 error:nil];
    NSString *dicts_string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *params = @{
        @"q" : text,
        @"le" : foreignLangauge,
        @"dicts" : dicts_string,
    };
    
    NSString *url = [NSString stringWithFormat:@"%@/jsonapi", kYoudaoDictURL];
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params, EZTranslateErrorRequestParamKey, nil];
    
    NSURLSessionTask *task = [self.jsonSession GET:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        NSString *message = nil;
        
        if (responseObject) {
            @try {
                EZYoudaoDictModel *model = [EZYoudaoDictModel mj_objectWithKeyValues:responseObject];
                [self.result setupWithYoudaoDictModel:model];
                completion(self.result, self.result.error);
                return;
            } @catch (NSException *exception) {
                MMLogError(@"有道翻译接口数据解析异常 %@", exception);
                message = @"有道翻译接口数据解析异常";
            }
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        self.result.error = [EZError errorWithType:EZErrorTypeAPI description: message  request:reqDict];
        completion(self.result, self.result.error);
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        self.result.error = [EZError errorWithType:EZErrorTypeNetwork description: nil request:reqDict];
        completion(self.result, self.result.error);
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}

// Get youdao fanyi cookie, and save it to NSUserDefaults.
- (void)requestYoudaoCookie {
    // https://fanyi.youdao.com/index.html#/
    NSString *cookieURL = [NSString stringWithFormat:@"%@/index.html#/", kYoudaoTranslatetURL];
    [self.networkManager requestCookieOfURL:cookieURL cookieName:@"OUTFOX_SEARCH_USER_ID" completion:^(NSString *cookie) {
        if (cookie.length) {
            [NSUserDefaults mm_write:cookie forKey:kYoudaoTranslatetURL];
        }
    }];
}

#pragma mark - New Web Translate, 2023.5

/// New Youdao web translate && dict API, Ref: https://github.com/Chen03/StaticeApp/blob/a8706aaf4806468a663d7986b901b09be5fc9319/Statice/Model/Search/Youdao.swift
- (void)webTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion {
    NSString *client = @"fanyideskweb";
    NSString *product = @"webfanyi";
    NSString *key = @"Vy4EQ1uwPkUoqvcP1nIu6WiAjxFeA3YW";
    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)([[NSDate date] timeIntervalSince1970] * 1000)];

    NSString *string = [NSString stringWithFormat:@"client=%@&mysticTime=%@&product=%@&key=%@", client, timestamp, product, key];
    NSString *sign = [string md5];
    
    NSString *pointParam = @"client,mysticTime,product";
    NSString *keyfrom = @"fanyi.web";
    NSString *appVersion = @"1.0.0";
    NSString *vendor = @"web";
    
    NSString *fromLanguage = [self languageCodeForLanguage:from];
    NSString *toLanguage = [self languageCodeForLanguage:to];
    
    text = [text trimToMaxLength:5000];
    
    NSDictionary *params = @{
        @"i" : text,
        @"from" : fromLanguage,
        @"to" : toLanguage,
        @"dictResult" : @"true",
        @"keyid" : @"webfanyi",
        @"sign" : sign,
        
        @"client" : client,
        @"product" : product,
        @"appVersion" : appVersion,
        @"vendor" : vendor,
        @"pointParam" : pointParam,
        @"mysticTime" : timestamp,
        @"keyfrom" : keyfrom,
    };
    
    NSDictionary *headers = @{
        @"User-Agent" : EZUserAgent,
        @"Referer" : kYoudaoTranslatetURL,
        @"Cookie" : self.cookie,
    };
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
    // default is AFJSONResponseSerializer
    manager.responseSerializer = serializer;
    
    // set headers
    for (NSString *key in headers.allKeys) {
        [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/webtranslate", kYoudaoDictURL];
    NSURLSessionTask *task = [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSData class]]) {
            NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSString *base64String = [string stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
            base64String = [base64String stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
            
            NSString *decodedString = [self decryptAESText:base64String];
            NSDictionary *dict = [decodedString mj_JSONObject];
            NSArray *translatedTexts = [self parseTranslateResult:dict];
            if (translatedTexts.count) {
                self.result.translatedResults = translatedTexts;
                completion(self.result, nil);
                return;
            }
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        
        [self requestYoudaoCookie];
        completion(self.result, error);
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}

- (NSString *)decryptAESText:(NSString *)encryptedText {
    NSString *key = @"ydsecret://query/key/B*RGygVywfNBwpmBaZg*WT7SIOUP2T0C9WHMZN39j^DAdaZhAnxvGcCY6VYFwnHl";
    NSString *iv = @"ydsecret://query/iv/C@lZe2YzHtZ2CYgaXKSVfsb7Y4QWHjITPPZ0nQp87fBeJ!Iv6v^6fvi2WN@bYpJ4";
    
    if (!encryptedText) {
        return nil;
    }
    
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [iv dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *keyDataMD5Data = [keyData md5];
    NSData *ivDataMD5Data = [ivData md5];
    
    //    NSString *decryptedText = [FWEncryptorAES decryptStrFromBase64:encryptedText Key:keyDataMD5Data IV:ivDataMD5Data];
    NSString *decryptedText = [encryptedText decryptAESWithKeyData:keyDataMD5Data ivData:ivDataMD5Data];
    
    return decryptedText;
}

#pragma mark -

/// Parse Youdao transalte.
- (NSArray<NSString *> *)parseTranslateResult:(NSDictionary *)dict {
    NSArray *translateResult = dict[@"translateResult"];
    
    NSMutableString *translatedText = [NSMutableString string];
    for (NSArray *results in translateResult) {
        for (NSDictionary *resultDict in results) {
            NSString *text = resultDict[@"tgt"];
            if (text) {
                [translatedText appendString:text];
            }
        }
    }
    NSArray *paragraphs = [translatedText toParagraphs];
    
    return paragraphs;
}


#pragma mark - AES Decrypt manually

- (NSString *)decryptAES:(NSString *)text {
    NSString *key = @"ydsecret://query/key/B*RGygVywfNBwpmBaZg*WT7SIOUP2T0C9WHMZN39j^DAdaZhAnxvGcCY6VYFwnHl";
    NSString *iv = @"ydsecret://query/iv/C@lZe2YzHtZ2CYgaXKSVfsb7Y4QWHjITPPZ0nQp87fBeJ!Iv6v^6fvi2WN@bYpJ4";
    
    if (text == nil || [text length] == 0) {
        return nil;
    }
    
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [iv dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *keyDataMD5Data = [keyData md5];
    NSData *ivDataMD5Data = [ivData md5];
    
    return [self decryptAES:text key:keyDataMD5Data iv:ivDataMD5Data];
}

- (nullable NSString *)decryptAES:(NSString *)cipherText key:(NSData *)key iv:(NSData *)iv {
    NSData *cipherData = [[NSData alloc] initWithBase64EncodedString:cipherText options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSMutableData *decryptedData = [NSMutableData dataWithLength:[cipherData length] + kCCBlockSizeAES128];
    size_t decryptedLength = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          [key bytes],
                                          [key length],
                                          [iv bytes],
                                          [cipherData bytes],
                                          [cipherData length],
                                          [decryptedData mutableBytes],
                                          [decryptedData length],
                                          &decryptedLength);
    if (cryptStatus == kCCSuccess) {
        [decryptedData setLength:decryptedLength];
        NSString *decryptedText = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
        return decryptedText;
    }
    
    return nil;
}

@end
