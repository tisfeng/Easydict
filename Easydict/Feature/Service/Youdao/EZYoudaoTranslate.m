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
#import "EZWebViewTranslator.h"
#import "EZTextWordUtils.h"

static NSString *const kYoudaoDictURL = @"https://www.youdao.com";
static NSString *const kYoudaoTranslatetURL = @"https://fanyi.youdao.com";
static NSString *const kYoudaoCookieKey = @"kYoudaoCookieKey";

// OUTFOX_SEARCH_USER_ID=1797292665@113.88.171.39; domain=.youdao.com; expires=Wed, 08-Jan-2053 02:18:55 GMT


@interface EZYoudaoTranslate ()

@property (nonatomic, strong) AFHTTPSessionManager *jsonSession;
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) EZWebViewTranslator *webViewTranslator;

@end


@implementation EZYoudaoTranslate

- (instancetype)init {
    if (self = [super init]) {
        [self requestYoudaoCookie];
    }
    return self;
}

- (EZWebViewTranslator *)webViewTranslator {
    if (!_webViewTranslator) {
        NSString *selector = @"p.trans-content";
        _webViewTranslator = [[EZWebViewTranslator alloc] init];
        _webViewTranslator.querySelector = selector;
        _webViewTranslator.queryModel = self.queryModel;
    }
    return _webViewTranslator;
}

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

- (AFHTTPSessionManager *)htmlSession {
    if (!_htmlSession) {
        AFHTTPSessionManager *htmlSession = [AFHTTPSessionManager manager];
        
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X "
         @"10_15_0) AppleWebKit/537.36 (KHTML, like "
         @"Gecko) Chrome/77.0.3865.120 Safari/537.36"
                 forHTTPHeaderField:@"User-Agent"];
        htmlSession.requestSerializer = requestSerializer;
        
        AFHTTPResponseSerializer *responseSerializer =
        [AFHTTPResponseSerializer serializer];
        responseSerializer.acceptableContentTypes =
        [NSSet setWithObjects:@"text/html", nil];
        htmlSession.responseSerializer = responseSerializer;
        
        _htmlSession = htmlSession;
    }
    return _htmlSession;
}

// Get youdao fanyi cookie, and save it to user defaults.
- (void)requestYoudaoCookie {
    // https://fanyi.youdao.com/index.html#/
    NSString *URLString = [NSString stringWithFormat:@"%@/index.html#/", kYoudaoTranslatetURL];
    [self.htmlSession GET:URLString parameters:nil progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:kYoudaoTranslatetURL]];
        // convert to OUTFOX_SEARCH_USER_ID=1797292665@113.88.171.39; domain=.youdao.com; expires=Wed, 08-Jan-2053 02:18:55 GMT
        NSString *cookieString = @"";
        for (NSHTTPCookie *cookie in cookies) {
            if ([cookie.name isEqualToString:@"OUTFOX_SEARCH_USER_ID"]) {
                cookieString = [NSString stringWithFormat:@"%@=%@; domain=%@; expires=%@", cookie.name, cookie.value, cookie.domain, cookie.expiresDate];
                break;
            }
        }
        if (cookieString.length) {
            [NSUserDefaults mm_write:cookieString forKey:kYoudaoCookieKey];
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        NSLog(@"request youdao cookie error: %@", error);
    }];
}


#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeYoudao;
}

- (EZQueryServiceType)queryServiceType {
    EZQueryServiceType type = EZQueryServiceTypeNone;
    BOOL enableTranslation = [[NSUserDefaults mm_readString:EZYoudaoTranslationKey defaultValue:@"1"] boolValue];
    BOOL enableDictionary = [[NSUserDefaults mm_readString:EZYoudaoDictionaryKey defaultValue:@"1"] boolValue];
    if (enableTranslation) {
        type = type | EZQueryServiceTypeTranslation;
    }
    if (enableDictionary) {
        type = type | EZQueryServiceTypeDictionary;
    }

    return type;
}

- (NSString *)name {
    return NSLocalizedString(@"youdao_dict", nil);
}

- (NSString *)link {
    return @"http://fanyi.youdao.com";
}

// Youdao word link, support 4 languages: en, ja, ko, fr, and to Chinese. https://www.youdao.com/result?word=good&lang=en
// means: en <-> zh-CHS, ja <-> zh-CHS, ko <-> zh-CHS, fr <-> zh-CHS, if language not in this list, then return nil.
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *encodedWord = [queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *foreignLangauge = [self youdaoDictForeignLangauge:queryModel];
    if (!foreignLangauge) {
        return nil;
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
    if ([EZLanguageManager isChineseLanguage:fromLanguage]) {
        foreignLangauge = [self languageCodeForLanguage:toLanguage];
    } else if ([EZLanguageManager isChineseLanguage:toLanguage]) {
        foreignLangauge = [self languageCodeForLanguage:fromLanguage];
    }
    
    if ([youdaoSupportedLanguageCodes containsObject:foreignLangauge]) {
        return foreignLangauge;
    }
    return nil;
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
                                        EZLanguageBurmese, @"my",
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
    
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:NO from:from to:to completion:completion]) {
        return;
    }
    
    [self queryYoudaoDictAndTranslation:text from:from to:to completion:completion];
}

- (void)queryYoudaoDictAndTranslation:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    if (!text.length) {
        completion(self.result, EZTranslateError(EZTranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    if (self.queryServiceType == EZQueryServiceTypeNone) {
        self.result.errorMessage = NSLocalizedString(@"query_has_no_result", nil);
        completion(self.result, nil);
        return;
    }
    
    // 1. Query dict.
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [self queryYoudaoDict:text from:from to:to completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
        if (error) {
            NSLog(@"queryYoudaoDict error: %@", error);
        }
        dispatch_group_leave(group);
    }];
    
    BOOL enableTranslation = self.queryServiceType & EZQueryServiceTypeTranslation;
    if (enableTranslation) {
        // 2.Query Youdao translate.
        dispatch_group_enter(group);
        [self youdaoWebTranslate:text from:from to:to completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
            if (error) {
                NSLog(@"translateYoudaoAPI error: %@", error);
                self.result.error = error;
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completion(self.result, self.result.error);
    });
}

- (void)queryYoudaoDict:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    if (!text.length) {
        completion(self.result, EZTranslateError(EZTranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    if (self.queryServiceType == EZQueryServiceTypeNone) {
        completion(self.result, nil);
        return;
    }
    
    BOOL enableDictionary = self.queryServiceType & EZQueryServiceTypeDictionary;
    
    // Youdao dict can query word, phrase, even short text.
    BOOL shouldQueryDictionary = [EZTextWordUtils shouldQueryDictionary:text language:from];
    
    NSString *foreignLangauge = [self youdaoDictForeignLangauge:self.queryModel];
    BOOL supportQueryDictionaryLanguage = foreignLangauge != nil;
    
    // If Youdao Dictionary does not support the language, try querying translate API.
    if (!enableDictionary || !supportQueryDictionaryLanguage || !shouldQueryDictionary) {
        self.result.errorMessage = NSLocalizedString(@"query_has_no_result", nil);
        completion(self.result, nil);
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
    NSString *url = @"https://dict.youdao.com/jsonapi";
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
                MMLogInfo(@"有道翻译接口数据解析异常 %@", exception);
                message = @"有道翻译接口数据解析异常";
            }
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        self.result.error = EZTranslateError(EZTranslateErrorTypeAPI, message, reqDict);
        completion(self.result, self.result.error);
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }

        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        self.result.error = EZTranslateError(EZTranslateErrorTypeNetwork, nil, reqDict);
        completion(self.result, self.result.error);
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}


/// Youdao web translate API
- (void)youdaoWebTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    // update cookie.
    [self requestYoudaoCookie];
    
    NSString *fromLanguage = [self languageCodeForLanguage:from];
    NSString *toLanguage = [self languageCodeForLanguage:to];
    
    NSString *cookie = [NSUserDefaults mm_read:kYoudaoCookieKey];
    if (!cookie) {
        cookie = @"OUTFOX_SEARCH_USER_ID=833782676@113.88.171.235; domain=.youdao.com; expires=2052-12-31 13:12:38 +0000";
    }
    
    // TODO: Handle cookie expiration cases.
    
    text = [text trimToMaxLength:5000];
    
    // Ref: https://mp.weixin.qq.com/s/AWL3et91N8T24cKs1v660g
    NSInteger timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    NSString *lts = [NSString stringWithFormat:@"%ld", timestamp];
    NSString *salt = [NSString stringWithFormat:@"%@%d", lts, arc4random() % 10];
    NSString *bv = [EZUserAgent md5];
    NSString *sign = [self signWithSalt:salt word:text];
    
    NSString *url = [NSString stringWithFormat:@"%@/translate_o?smartresult=dict&smartresult=rule", kYoudaoTranslatetURL];
    NSDictionary *params = @{
        @"salt" : salt,
        @"sign" : sign,
        @"lts" : lts,
        @"bv" : bv,
        @"i" : text,
        @"from" : fromLanguage,
        @"to" : toLanguage,
        @"smartresult" : @"dict",
        @"client" : @"fanyideskweb",
        @"doctype" : @"json",
        @"version" : @"2.1",
        @"keyfrom" : @"fanyi.web",
        @"action" : @"FY_BY_REALTlME",
    };
    
    NSDictionary *headers = @{
        @"User-Agent" : EZUserAgent,
        @"Referer" : kYoudaoTranslatetURL,
        @"Cookie" : cookie,
    };
    
    // set headers
    for (NSString *key in headers.allKeys) {
        [self.jsonSession.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
    }
    
    NSURLSessionTask *task = [self.jsonSession POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)responseObject;
            NSString *errorCode = dict[@"errorCode"];
            if (errorCode.integerValue == 0) {
                NSArray *translateResult = dict[@"translateResult"];
                NSMutableArray *texts = [NSMutableArray array];
                for (NSArray *results in translateResult) {
                    for (NSDictionary *resultDict in results) {
                        NSString *text = resultDict[@"tgt"];
                        if (text.length) {
                            [texts addObject:text.trim];
                        }
                    }
                }
                self.result.normalResults = texts;
                completion(self.result, nil);
                return;
            }
        }
        completion(self.result, EZTranslateError(EZTranslateErrorTypeAPI, @"翻译失败", responseObject));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        completion(self.result, EZTranslateError(EZTranslateErrorTypeNetwork, nil, error));
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}

- (NSString *)signWithSalt:(NSString *)salt word:(NSString *)word {
    NSString *sign = [NSString stringWithFormat:@"fanyideskweb%@%@Ygy_4c=r#e#4EX^NUGUc5", word, salt];
    return [sign md5];
}

// TODO: Use a stable Youdao translation API.
- (void)youdaoAIDemoTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
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
                EZYoudaoTranslateResponse *response = [EZYoudaoTranslateResponse mj_objectWithKeyValues:responseObject];
                if (response && response.errorCode.integerValue == 0) {
                    result.queryText = text;
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
                    EZYoudaoTranslateResponseBasic *basic = response.basic;
                    if (basic) {
                        EZTranslateWordResult *wordResult = [EZTranslateWordResult new];
                        
                        // 解析音频
                        NSMutableArray *phoneticArray = [NSMutableArray array];
                        if (basic.us_phonetic && basic.us_speech) {
                            EZTranslatePhonetic *phonetic = [EZTranslatePhonetic new];
                            phonetic.name = NSLocalizedString(@"us_phonetic", nil);
                            phonetic.value = basic.us_phonetic;
                            phonetic.speakURL = basic.us_speech;
                            [phoneticArray addObject:phonetic];
                        }
                        if (basic.uk_phonetic && basic.uk_speech) {
                            EZTranslatePhonetic *phonetic = [EZTranslatePhonetic new];
                            phonetic.name = NSLocalizedString(@"uk_phonetic", nil);
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
                        } else if ([result.from isEqualToString:EZLanguageSimplifiedChinese] && [result.to isEqualToString:EZLanguageEnglish]) {
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
                            // If has assigned Youdao dict data, use it directly.
                            if (!result.wordResult) {
                                result.wordResult = wordResult;
                            }
                            // 如果是单词或短语，优先使用美式发音
                            if ([result.from isEqualToString:EZLanguageEnglish] && [result.to isEqualToString:EZLanguageSimplifiedChinese] && wordResult.phonetics.firstObject.speakURL.length) {
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
                    message = [NSString stringWithFormat:@"错误码 %@", response.errorCode];
                }
            } @catch (NSException *exception) {
                MMLogInfo(@"有道翻译翻译接口数据解析异常 %@", exception);
                message = @"有道翻译翻译接口数据解析异常";
            }
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        completion(self.result, EZTranslateError(EZTranslateErrorTypeAPI, message ?: nil, reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(self.result, EZTranslateError(EZTranslateErrorTypeNetwork, nil, reqDict));
    }];
}

- (void)detectText:(NSString *)text completion:(void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto, EZTranslateError(EZTranslateErrorTypeParam, @"识别语言的文本为空", nil));
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
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }
    
    [super textToAudio:text fromLanguage:from completion:completion];
}

- (void)youdaoAIDemoTextToAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }
    
    [self youdaoAIDemoTranslate:text from:from to:EZLanguageAuto completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
        if (result) {
            if (result.fromSpeakURL.length) {
                completion(result.fromSpeakURL, nil);
                return;
            }
        }
        
        //        NSDictionary *params = @{
        //            EZTranslateErrorRequestParamKey : @{
        //                @"text" : text ?: @"",
        //                @"from" : from,
        //            },
        //        };
        //        completion(nil, EZTranslateError(EZTranslateErrorTypeUnsupportLanguage, @"有道翻译不支持获取该语言音频", params));
        
        [super textToAudio:text fromLanguage:from completion:completion];
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
                if (!(([EZOCRResult.to isEqualToString:EZLanguageSimplifiedChinese] || [EZOCRResult.to isEqualToString:EZLanguageEnglish]) && ![EZOCRResult.mergedText containsString:@" "])) {
                    // 直接回调翻译结果
                    NSLog(@"直接输出翻译结果");
                    ocrSuccess(EZOCRResult, NO);
                    EZQueryResult *result = [EZQueryResult new];
                    result.queryText = EZOCRResult.mergedText;
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
