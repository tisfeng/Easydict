//
//  EZBaiduService.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBaiduTranslate.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "EZBaiduTranslateResponse.h"

static NSString *const kBaiduTranslateURL = @"https://fanyi.baidu.com";

@interface EZBaiduTranslate ()

@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic, strong) JSValue *jsFunction;
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) AFHTTPSessionManager *jsonSession;

@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *gtk;
@property (nonatomic, assign) NSInteger error997Count;

@end


@implementation EZBaiduTranslate

- (JSContext *)jsContext {
    if (!_jsContext) {
        JSContext *jsContext = [JSContext new];
        NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"baidu-translate-sign" ofType:@"js"];
        NSString *jsString = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
        // 加载方法
        [jsContext evaluateScript:jsString];
        _jsContext = jsContext;
    }
    return _jsContext;
}

- (JSValue *)jsFunction {
    if (!_jsFunction) {
        _jsFunction = [self.jsContext objectForKeyedSubscript:@"token"];
    }
    return _jsFunction;
}

- (AFHTTPSessionManager *)htmlSession {
    if (!_htmlSession) {
        AFHTTPSessionManager *htmlSession = [AFHTTPSessionManager manager];
        
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        [requestSerializer setValue:@"BAIDUID=0F8E1A72A51EE47B7CA0A81711749C00:FG=1;" forHTTPHeaderField:@"Cookie"];
        htmlSession.requestSerializer = requestSerializer;
        
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
        htmlSession.responseSerializer = responseSerializer;
        
        _htmlSession = htmlSession;
    }
    return _htmlSession;
}

- (AFHTTPSessionManager *)jsonSession {
    if (!_jsonSession) {
        AFHTTPSessionManager *jsonSession = [AFHTTPSessionManager manager];
        
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        [requestSerializer setValue:@"BAIDUID=0F8E1A72A51EE47B7CA0A81711749C00:FG=1;" forHTTPHeaderField:@"Cookie"];
        jsonSession.requestSerializer = requestSerializer;
        
        AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
        jsonSession.responseSerializer = responseSerializer;
        
        _jsonSession = jsonSession;
    }
    return _jsonSession;
}

#pragma mark -

- (void)sendGetTokenAndGtkRequestWithCompletion:(void (^)(NSString *token, NSString *gtk, NSError *error))completion {
    NSString *url = kBaiduTranslateURL;
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObject:url forKey:EZTranslateErrorRequestURLKey];
    
    [self.htmlSession GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        NSString *html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        // token: '6d55d690ce5ade4a1fae243892f83ca6',
        NSString *tokenPattern = @"token: '(.*?)',";
        NSString *token = [self getStringValueFromHtml:html pattern:tokenPattern];
        
        // window.gtk = '320305.131321201'; // default value ?
        NSString *gtkPattern = @"window.gtk = \"(.*?)\";";
        NSString *gtk = [self getStringValueFromHtml:html pattern:gtkPattern];
        
        if (token.length && gtk.length) {
            completion(token, gtk, nil);
        } else {
            [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
            completion(nil, nil, EZTranslateError(EZTranslateErrorTypeAPI, @"获取 token 失败", reqDict));
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, nil, EZTranslateError(EZTranslateErrorTypeNetwork, @"获取 token 失败", reqDict));
    }];
}

/// Get string value from html
- (NSString *)getStringValueFromHtml:(NSString *)html pattern:(NSString *)pattern {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange range = [match rangeAtIndex:1];
        NSString *subString = [html substringWithRange:range];
        return subString;
    }
    return nil;
}

- (void)sendTranslateRequest:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    // 获取sign
    JSValue *value = [self.jsFunction callWithArguments:@[ text, self.gtk ]];
    NSString *sign = [value toString];
    
    NSString *url = [kBaiduTranslateURL stringByAppendingString:@"/v2transapi"];
    NSDictionary *params = @{
        @"from" : [self languageCodeForLanguage:from],
        @"to" : [self languageCodeForLanguage:to],
        @"query" : text,
        @"simple_means_flag" : @3,
        @"transtype" : @"realtime",
        @"domain" : @"common",
        @"sign" : sign,
        @"token" : self.token,
    };
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params, EZTranslateErrorRequestParamKey, nil];
    
    mm_weakify(self)
    
    [self.jsonSession POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        mm_strongify(self)
        NSString *message = nil;
        if (responseObject) {
            @try {
                EZBaiduTranslateResponse *response = [EZBaiduTranslateResponse mj_objectWithKeyValues:responseObject];
                if (response) {
                    if (response.error == 0) {
                        self.error997Count = 0;
                        
                        EZQueryResult *result = self.result;
                        
                        result.text = text;
                        result.link = [NSString stringWithFormat:@"%@/#%@/%@/%@", kBaiduTranslateURL, response.trans_result.from, response.trans_result.to, text.mm_urlencode];
                        result.from = [self languageEnumFromCode:response.trans_result.from] ?: from;
                        result.to = [self languageEnumFromCode:response.trans_result.to] ?: to;
                        
                        // 解析单词释义
                        [response.dict_result.simple_means mm_anyPut:^(EZBaiduTranslateResponseSimpleMean *_Nonnull simple_means) {
                            EZTranslateWordResult *wordResult = [EZTranslateWordResult new];
                            
                            [simple_means.symbols.firstObject mm_anyPut:^(EZBaiduTranslateResponseSymbol *_Nonnull symbol) {
                                // 解析音标
                                NSMutableArray *phonetics = [NSMutableArray array];
                                if (symbol.ph_am.length) {
                                    [phonetics addObject:[EZTranslatePhonetic mm_anyMake:^(EZTranslatePhonetic *_Nonnull obj) {
                                        obj.name = @"美";
                                        obj.value = symbol.ph_am;
                                        obj.speakURL = [self getAudioURLWithText:result.text language:@"en"];
                                    }]];
                                }
                                if (symbol.ph_en.length) {
                                    [phonetics addObject:[EZTranslatePhonetic mm_anyMake:^(EZTranslatePhonetic *_Nonnull obj) {
                                        obj.name = @"英";
                                        obj.value = symbol.ph_en;
                                        obj.speakURL = [self getAudioURLWithText:result.text language:@"uk"];
                                    }]];
                                }
                                wordResult.phonetics = phonetics.count ? phonetics.copy : nil;
                                
                                // 解析词性词义
                                NSMutableArray *parts = [NSMutableArray array];
                                [symbol.parts enumerateObjectsUsingBlock:^(EZBaiduTranslateResponsePart *_Nonnull resultPart, NSUInteger idx, BOOL *_Nonnull stop) {
                                    EZTranslatePart *part = [EZTranslatePart mm_anyMake:^(EZTranslatePart *_Nonnull obj) {
                                        obj.part = resultPart.part.length ? resultPart.part : (resultPart.part_name.length ? resultPart.part_name : nil);
                                        obj.means = [resultPart.means mm_where:^BOOL(id mean, NSUInteger idx, BOOL *_Nonnull stop) {
                                            // 如果中文查词时，会是字典；这个API的设计，真的一言难尽
                                            return [mean isKindOfClass:NSString.class];
                                        }];
                                    }];
                                    if (part.means.count) {
                                        [parts addObject:part];
                                    }
                                }];
                                wordResult.parts = parts.count ? parts.copy : nil;
                            }];
                            
                            // 解析其他形式
                            [simple_means.exchange mm_anyPut:^(EZBaiduTranslateResponseExchange *_Nonnull exchange) {
                                NSMutableArray *exchanges = [NSMutableArray array];
                                if (exchange.word_third.count) {
                                    [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                        obj.name = @"第三人称单数";
                                        obj.words = exchange.word_third;
                                    }]];
                                }
                                if (exchange.word_pl.count) {
                                    [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                        obj.name = @"复数";
                                        obj.words = exchange.word_pl;
                                    }]];
                                }
                                if (exchange.word_er.count) {
                                    [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                        obj.name = @"比较级";
                                        obj.words = exchange.word_er;
                                    }]];
                                }
                                if (exchange.word_est.count) {
                                    [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                        obj.name = @"最高级";
                                        obj.words = exchange.word_est;
                                    }]];
                                }
                                if (exchange.word_past.count) {
                                    [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                        obj.name = @"过去式";
                                        obj.words = exchange.word_past;
                                    }]];
                                }
                                if (exchange.word_done.count) {
                                    [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                        obj.name = @"过去分词";
                                        obj.words = exchange.word_done;
                                    }]];
                                }
                                if (exchange.word_ing.count) {
                                    [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                        obj.name = @"现在分词";
                                        obj.words = exchange.word_ing;
                                    }]];
                                }
                                if (exchange.word_proto.count) {
                                    [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                        obj.name = @"词根";
                                        obj.words = exchange.word_proto;
                                    }]];
                                }
                                wordResult.exchanges = exchanges.count ? exchanges.copy : nil;
                            }];
                            
                            // 解析中文查词
                            if (simple_means.word_means.count) {
                                // 这个时候去解析 simple_means["symbols"][0]["parts"][0]["means"]
                                NSMutableArray<EZTranslateSimpleWord *> *words = [NSMutableArray array];
                                NSArray<NSDictionary *> *means = simple_means.symbols.firstObject.parts.firstObject.means;
                                [means enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                    if ([obj isKindOfClass:NSDictionary.class]) {
                                        /**
                                         "text": "rejoice",
                                         "part": "v.",
                                         "word_mean": "rejoice",
                                         "means": ["\u975e\u5e38\u9ad8\u5174", "\u6df1\u611f\u6b23\u559c"]
                                         "isSeeAlso": "1"
                                         */
                                        if (![obj objectForKey:@"isSeeAlso"]) {
                                            EZTranslateSimpleWord *simpleWord = [EZTranslateSimpleWord new];
                                            simpleWord.word = [obj objectForKey:@"text"];
                                            simpleWord.part = [obj objectForKey:@"part"];
                                            if (!simpleWord.part.length) {
                                                simpleWord.part = @"misc.";
                                            }
                                            NSArray *means = [obj objectForKey:@"means"];
                                            if ([means isKindOfClass:NSArray.class]) {
                                                simpleWord.means = [means mm_where:^BOOL(id _Nonnull mean, NSUInteger idx, BOOL *_Nonnull stop) {
                                                    return [mean isKindOfClass:NSString.class];
                                                }];
                                            }
                                            if (simpleWord.word.length) {
                                                [words addObject:simpleWord];
                                            }
                                        }
                                    }
                                }];
                                if (words.count) {
                                    wordResult.simpleWords = [words sortedArrayUsingComparator:^NSComparisonResult(EZTranslateSimpleWord *_Nonnull obj1, EZTranslateSimpleWord *_Nonnull obj2) {
                                        if ([obj2.part isEqualToString:@"misc."]) {
                                            return NSOrderedAscending;
                                        } else if ([obj1.part isEqualToString:@"misc."]) {
                                            return NSOrderedDescending;
                                        } else {
                                            return [obj1.part compare:obj2.part];
                                        }
                                    }];
                                }
                            }
                            
                            // 至少要有词义或单词组才认为有单词翻译结果
                            if (wordResult.parts || wordResult.simpleWords) {
                                result.wordResult = wordResult;
                            }
                        }];
                        
                        // 解析普通释义
                        NSMutableArray *normalResults = [NSMutableArray array];
                        [response.trans_result.data enumerateObjectsUsingBlock:^(EZBaiduTranslateResponseData *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            [normalResults addObject:obj.dst];
                        }];
                        result.normalResults = normalResults.count ? normalResults.copy : nil;
                        
                        // 原始数据
                        result.raw = responseObject;
                        
                        if (result.wordResult || result.normalResults) {
                            completion(result, nil);
                            return;
                        }
                        
                        message = @"百度翻译结果为空";

                    } else if (response.error == 997) {
                        // token 失效，重新获取
                        self.error997Count++;
                        // 记录连续失败，避免无限循环
                        if (self.error997Count < 3) {
                            self.token = nil;
                            self.gtk = nil;
                            [self translate:text from:from to:to completion:completion];
                            return;
                        } else {
                            message = @"百度翻译获取 token 失败";
                        }
                    } else {
                        message = [NSString stringWithFormat:@"翻译失败，错误码 %zd", response.error];
                    }
                }
            } @catch (NSException *exception) {
                MMLogInfo(@"百度翻译接口数据解析异常 %@", exception);
                message = @"百度翻译接口数据解析异常";
            }
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        completion(self.result, EZTranslateError(EZTranslateErrorTypeAPI, message ?: @"翻译失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(self.result, EZTranslateError(EZTranslateErrorTypeNetwork, @"翻译失败", reqDict));
    }];
}

#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeBaidu;
}

- (NSString *)identifier {
    return @"Baidu";
}

- (NSString *)name {
    return @"百度翻译";
}

- (NSString *)link {
    return kBaiduTranslateURL;
}

// https://fanyi.baidu.com/#en/zh/good
- (NSString *)wordLink {
    NSString *from = [self languageCodeForLanguage:self.queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:self.queryModel.autoTargetLanguage];
    NSString *text = [self.queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    return [NSString stringWithFormat:@"%@#%@/%@/%@", kBaiduTranslateURL, from, to, text];
}

//- (MMOrderedDictionary *)supportLanguagesDictionary {
//    return [[MMOrderedDictionary alloc] initWithKeysAndObjects:
//                                            @(EZLanguageAuto), @"auto", @(EZLanguageSimplifiedChinese), @"zh", @(EZLanguageTraditionalChinese), @"cht", @(EZLanguageEnglish), @"en", @(EZLanguage_yue), @"yue", @(EZLanguage_wyw), @"wyw", @(EZLanguage_ja), @"jp", @(EZLanguage_ko), @"kor", @(EZLanguage_fr), @"fra", @(EZLanguage_es), @"spa", @(EZLanguage_th), @"th", @(EZLanguage_ar), @"ara", @(EZLanguage_ru), @"ru", @(EZLanguage_pt), @"pt", @(EZLanguage_de), @"de", @(EZLanguage_it), @"it", @(EZLanguage_el), @"el", @(EZLanguage_nl), @"nl", @(EZLanguage_pl), @"pl", @(EZLanguage_bg), @"bul", @(EZLanguage_et), @"est", @(EZLanguage_da), @"dan", @(EZLanguage_fi), @"fin", @(EZLanguage_cs), @"cs", @(EZLanguage_ro), @"rom", @(EZLanguage_sl), @"slo", @(EZLanguage_sv), @"swe", @(EZLanguage_hu), @"hu", @(EZLanguage_vi), @"vie", nil];
//}

// get supportLanguagesDictionary, key is EZLanguage, value is NLLanguage, such as EZLanguageAuto, NLLanguageUndetermined
- (MMOrderedDictionary *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, @"auto",
                                        EZLanguageSimplifiedChinese, @"zh",
                                        EZLanguageTraditionalChinese, @"cht",
                                        EZLanguageEnglish, @"en",
                                        EZLanguageJapanese, @"jp",
                                        EZLanguageKorean, @"kor",
                                        EZLanguageFrench, @"fra",
                                        EZLanguageSpanish, @"spa",
                                        EZLanguagePortuguese, @"pt",
                                        EZLanguageItalian, @"it",
                                        EZLanguageGerman, @"de",
                                        EZLanguageRussian, @"ru",
                                        EZLanguageArabic, @"ara",
                                        EZLanguageSwedish, @"swe",
                                        EZLanguageRomanian, @"rom",
                                        EZLanguageThai, @"th",
                                        EZLanguageSlovak, @"slo",
                                        EZLanguageDutch, @"nl",
                                        EZLanguageHungarian, @"hu",
                                        EZLanguageGreek, @"el",
                                        EZLanguageDanish, @"dan",
                                        EZLanguageFinnish, @"fin",
                                        EZLanguagePolish, @"pl",
                                        EZLanguageCzech, @"cs",
                                        EZLanguageTurkish, @"tr",
                                        EZLanguageLithuanian, @"lt",
                                        EZLanguageLatvian, @"lv",
                                        EZLanguageUkrainian, @"uk",
                                        EZLanguageBulgarian, @"bul",
                                        EZLanguageIndonesian, @"id",
                                        EZLanguageMalay, @"ms",
                                        EZLanguageSlovenian, @"sl",
                                        EZLanguageEstonian, @"est",
                                        EZLanguageVietnamese, @"vie",
                                        EZLanguagePersian, @"per",
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

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    void (^request)(void) = ^(void) {
        void (^translateBlock)(EZLanguage) = ^(EZLanguage from) {
            [self sendTranslateRequest:text from:from to:to completion:completion];
        };
        
        if (from == EZLanguageAuto) {
            [self detect:text completion:^(EZLanguage lang, NSError *_Nullable error) {
                if (error) {
                    completion(nil, error);
                    return;
                }
                translateBlock(lang);
            }];
        } else {
            translateBlock(from);
        }
    };
    
    if (!self.token || !self.gtk) {
        // 获取 token
        MMLogInfo(@"百度翻译请求 token");
        mm_weakify(self)
        [self sendGetTokenAndGtkRequestWithCompletion:^(NSString *token, NSString *gtk, NSError *error) {
            mm_strongify(self)
            MMLogInfo(@"百度翻译回调 token: %@, gtk: %@", token, gtk);
            if (error) {
                completion(nil, error);
                return;
            }
            self.token = token;
            self.gtk = gtk;
            request();
        }];
    } else {
        // 直接请求
        request();
    }
}

- (void)detect:(NSString *)text completion:(nonnull void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto, EZTranslateError(EZTranslateErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }
    
    // 字符串太长会导致获取语言的接口报错
    NSString *queryString = text;
    if (queryString.length >= 73) {
        queryString = [queryString substringToIndex:73];
    }
    
    NSString *url = [kBaiduTranslateURL stringByAppendingString:@"/langdetect"];
    NSDictionary *params = @{@"query" : queryString};
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params, EZTranslateErrorRequestParamKey, nil];
    
    mm_weakify(self);
    [self.jsonSession POST:[kBaiduTranslateURL stringByAppendingString:@"/langdetect"] parameters:@{@"query" : queryString} progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        mm_strongify(self);
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *jsonResult = responseObject;
            NSString *from = [jsonResult objectForKey:@"lan"];
            if ([from isKindOfClass:NSString.class] && from.length) {
                completion([self languageEnumFromCode:from], nil);
            } else {
                completion(EZLanguageAuto, EZTranslateError(EZTranslateErrorTypeUnsupportLanguage, nil, reqDict));
            }
            return;
        }
        completion(EZLanguageAuto, EZTranslateError(EZTranslateErrorTypeAPI, @"判断语言失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(EZLanguageAuto, EZTranslateError(EZTranslateErrorTypeNetwork, @"判断语言失败", reqDict));
    }];
}

- (void)audio:(NSString *)text from:(EZLanguage)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }
    
    if (from == EZLanguageAuto) {
        [self detect:text completion:^(EZLanguage lang, NSError *_Nullable error) {
            if (!error) {
                completion([self getAudioURLWithText:text language:[self languageCodeForLanguage:lang]], nil);
            } else {
                completion(nil, error);
            }
        }];
    } else {
        completion([self getAudioURLWithText:text language:[self languageCodeForLanguage:from]], nil);
    }
}

- (NSString *)getAudioURLWithText:(NSString *)text language:(NSString *)language {
    return [NSString stringWithFormat:@"%@/gettts?lan=%@&text=%@&spd=3&source=web", kBaiduTranslateURL, language, text.mm_urlencode];
}

- (void)ocr:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    
    NSData *data = [image mm_PNGData];
    NSString *fromLang = (from == EZLanguageAuto) ? [self languageCodeForLanguage:EZLanguageEnglish] : [self languageCodeForLanguage:from];
    NSString *toLang = nil;
    if (to == EZLanguageAuto) {
        toLang = [EZLanguageManager targetLanguageWithSourceLanguage:from];
    } else {
        toLang = [self languageCodeForLanguage:to];
    }
    
    NSString *url = [kBaiduTranslateURL stringByAppendingPathComponent:@"/getocr"];
    NSDictionary *params = @{
        @"image" : data,
        @"from" : fromLang,
        @"to" : toLang
    };
    // 图片 base64 字符串过长，暂不打印
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, @{@"from" : fromLang, @"to" : toLang}, EZTranslateErrorRequestParamKey, nil];
    
    mm_weakify(self);
    [self.jsonSession POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> _Nonnull formData) {
        [formData appendPartWithFileData:data name:@"image" fileName:@"blob" mimeType:@"image/png"];
    } progress:^(NSProgress *_Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        mm_strongify(self);
        NSString *message = nil;
        @try {
            if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *jsonResult = responseObject;
                NSDictionary *data = [jsonResult objectForKey:@"data"];
                if (data && [data isKindOfClass:[NSDictionary class]]) {
                    EZOCRResult *result = [EZOCRResult new];
                    NSString *from = [data objectForKey:@"from"];
                    if (from && [from isKindOfClass:NSString.class]) {
                        result.from = [self languageEnumFromCode:from];
                    }
                    NSString *to = [data objectForKey:@"to"];
                    if (to && [to isKindOfClass:NSString.class]) {
                        result.to = [self languageEnumFromCode:to];
                    }
                    NSArray<NSString *> *src = [data objectForKey:@"src"];
                    if (src && src.count) {
                        result.texts = [src mm_map:^id _Nullable(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            if ([obj isKindOfClass:NSString.class] && obj.length) {
                                EZOCRText *text = [EZOCRText new];
                                text.text = obj;
                                return text;
                            }
                            return nil;
                        }];
                    }
                    result.raw = responseObject;
                    if (result.texts.count) {
                        // 百度翻译按图片中的行进行分割，可能是一句话，所以用空格拼接
                        result.mergedText = [NSString mm_stringByCombineComponents:[result.ocrTextArray mm_map:^id _Nullable(EZOCRText *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            return obj.text;
                        }] separatedString:@" "];
                        completion(result, nil);
                        return;
                    }
                }
            }
        } @catch (NSException *exception) {
            MMLogInfo(@"百度翻译OCR接口数据解析异常 %@", exception);
            message = @"百度翻译OCR接口数据解析异常";
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        completion(nil, EZTranslateError(EZTranslateErrorTypeAPI, message ?: @"识别图片文本失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, EZTranslateError(EZTranslateErrorTypeNetwork, @"识别图片文本失败", reqDict));
    }];
}

- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable, EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, nil, EZTranslateError(EZTranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    mm_weakify(self);
    [self ocr:image from:from to:to completion:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        mm_strongify(self);
        if (ocrResult) {
            ocrSuccess(ocrResult, YES);
            [self translate:ocrResult.mergedText from:from to:to completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
                completion(ocrResult, result, error);
            }];
        } else {
            completion(nil, nil, error);
        }
    }];
}

@end
