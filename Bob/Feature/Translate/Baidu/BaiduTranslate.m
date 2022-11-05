//
//  BaiduTranslate.m
//  Bob
//
//  Created by ripper on 2019/10/19.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "BaiduTranslate.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "BaiduTranslateResponse.h"

#define kBaiduRootPage @"https://fanyi.baidu.com"


@interface BaiduTranslate ()

@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic, strong) JSValue *jsFunction;
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) AFHTTPSessionManager *jsonSession;

@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *gtk;
@property (nonatomic, assign) NSInteger error997Count;

@end


@implementation BaiduTranslate

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
    NSString *url = kBaiduRootPage;
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObject:url forKey:TranslateErrorRequestURLKey];
    
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
            [reqDict setObject:responseObject ?: [NSNull null] forKey:TranslateErrorRequestResponseKey];
            completion(nil, nil, TranslateError(TranslateErrorTypeAPI, @"获取 token 失败", reqDict));
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:TranslateErrorRequestErrorKey];
        completion(nil, nil, TranslateError(TranslateErrorTypeNetwork, @"获取 token 失败", reqDict));
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

- (void)sendTranslateRequest:(NSString *)text from:(Language)from to:(Language)to completion:(nonnull void (^)(TranslateResult *_Nullable, NSError *_Nullable))completion {
    // 获取sign
    JSValue *value = [self.jsFunction callWithArguments:@[ text, self.gtk ]];
    NSString *sign = [value toString];
    
    NSString *url = [kBaiduRootPage stringByAppendingString:@"/v2transapi"];
    NSDictionary *params = @{
        @"from" : [self languageStringFromEnum:from],
        @"to" : [self languageStringFromEnum:to],
        @"query" : text,
        @"simple_means_flag" : @3,
        @"transtype" : @"realtime",
        @"domain" : @"common",
        @"sign" : sign,
        @"token" : self.token,
    };
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, TranslateErrorRequestURLKey, params, TranslateErrorRequestParamKey, nil];
    
    mm_weakify(self)
    
    [self.jsonSession POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        mm_strongify(self)
        NSString *message = nil;
        if (responseObject) {
            @try {
                BaiduTranslateResponse *response = [BaiduTranslateResponse mj_objectWithKeyValues:responseObject];
                if (response) {
                    if (response.error == 0) {
                        self.error997Count = 0;
                        
                        TranslateResult *result = [TranslateResult new];
                        result.queryType = self.queryType;
                        
                        result.text = text;
                        result.link = [NSString stringWithFormat:@"%@/#%@/%@/%@", kBaiduRootPage, response.trans_result.from, response.trans_result.to, text.mm_urlencode];
                        result.from = [self languageEnumFromString:response.trans_result.from] ?: from;
                        result.to = [self languageEnumFromString:response.trans_result.to] ?: to;
                        
                        // 解析单词释义
                        [response.dict_result.simple_means mm_anyPut:^(BaiduTranslateResponseSimpleMean *_Nonnull simple_means) {
                            TranslateWordResult *wordResult = [TranslateWordResult new];
                            
                            [simple_means.symbols.firstObject mm_anyPut:^(BaiduTranslateResponseSymbol *_Nonnull symbol) {
                                // 解析音标
                                NSMutableArray *phonetics = [NSMutableArray array];
                                if (symbol.ph_am.length) {
                                    [phonetics addObject:[TranslatePhonetic mm_anyMake:^(TranslatePhonetic *_Nonnull obj) {
                                        obj.name = @"美";
                                        obj.value = symbol.ph_am;
                                        obj.speakURL = [self getAudioURLWithText:result.text language:@"en"];
                                    }]];
                                }
                                if (symbol.ph_en.length) {
                                    [phonetics addObject:[TranslatePhonetic mm_anyMake:^(TranslatePhonetic *_Nonnull obj) {
                                        obj.name = @"英";
                                        obj.value = symbol.ph_en;
                                        obj.speakURL = [self getAudioURLWithText:result.text language:@"uk"];
                                    }]];
                                }
                                wordResult.phonetics = phonetics.count ? phonetics.copy : nil;
                                
                                // 解析词性词义
                                NSMutableArray *parts = [NSMutableArray array];
                                [symbol.parts enumerateObjectsUsingBlock:^(BaiduTranslateResponsePart *_Nonnull resultPart, NSUInteger idx, BOOL *_Nonnull stop) {
                                    TranslatePart *part = [TranslatePart mm_anyMake:^(TranslatePart *_Nonnull obj) {
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
                            [simple_means.exchange mm_anyPut:^(BaiduTranslateResponseExchange *_Nonnull exchange) {
                                NSMutableArray *exchanges = [NSMutableArray array];
                                if (exchange.word_third.count) {
                                    [exchanges addObject:[TranslateExchange mm_anyMake:^(TranslateExchange *_Nonnull obj) {
                                        obj.name = @"第三人称单数";
                                        obj.words = exchange.word_third;
                                    }]];
                                }
                                if (exchange.word_pl.count) {
                                    [exchanges addObject:[TranslateExchange mm_anyMake:^(TranslateExchange *_Nonnull obj) {
                                        obj.name = @"复数";
                                        obj.words = exchange.word_pl;
                                    }]];
                                }
                                if (exchange.word_er.count) {
                                    [exchanges addObject:[TranslateExchange mm_anyMake:^(TranslateExchange *_Nonnull obj) {
                                        obj.name = @"比较级";
                                        obj.words = exchange.word_er;
                                    }]];
                                }
                                if (exchange.word_est.count) {
                                    [exchanges addObject:[TranslateExchange mm_anyMake:^(TranslateExchange *_Nonnull obj) {
                                        obj.name = @"最高级";
                                        obj.words = exchange.word_est;
                                    }]];
                                }
                                if (exchange.word_past.count) {
                                    [exchanges addObject:[TranslateExchange mm_anyMake:^(TranslateExchange *_Nonnull obj) {
                                        obj.name = @"过去式";
                                        obj.words = exchange.word_past;
                                    }]];
                                }
                                if (exchange.word_done.count) {
                                    [exchanges addObject:[TranslateExchange mm_anyMake:^(TranslateExchange *_Nonnull obj) {
                                        obj.name = @"过去分词";
                                        obj.words = exchange.word_done;
                                    }]];
                                }
                                if (exchange.word_ing.count) {
                                    [exchanges addObject:[TranslateExchange mm_anyMake:^(TranslateExchange *_Nonnull obj) {
                                        obj.name = @"现在分词";
                                        obj.words = exchange.word_ing;
                                    }]];
                                }
                                if (exchange.word_proto.count) {
                                    [exchanges addObject:[TranslateExchange mm_anyMake:^(TranslateExchange *_Nonnull obj) {
                                        obj.name = @"词根";
                                        obj.words = exchange.word_proto;
                                    }]];
                                }
                                wordResult.exchanges = exchanges.count ? exchanges.copy : nil;
                            }];
                            
                            // 解析中文查词
                            if (simple_means.word_means.count) {
                                // 这个时候去解析 simple_means["symbols"][0]["parts"][0]["means"]
                                NSMutableArray<TranslateSimpleWord *> *words = [NSMutableArray array];
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
                                            TranslateSimpleWord *simpleWord = [TranslateSimpleWord new];
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
                                    wordResult.simpleWords = [words sortedArrayUsingComparator:^NSComparisonResult(TranslateSimpleWord *_Nonnull obj1, TranslateSimpleWord *_Nonnull obj2) {
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
                        [response.trans_result.data enumerateObjectsUsingBlock:^(BaiduTranslateResponseData *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            [normalResults addObject:obj.dst];
                        }];
                        result.normalResults = normalResults.count ? normalResults.copy : nil;
                        
                        // 原始数据
                        result.raw = responseObject;
                        
                        if (result.wordResult || result.normalResults) {
                            completion(result, nil);
                            return;
                        }
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
        [reqDict setObject:responseObject ?: [NSNull null] forKey:TranslateErrorRequestResponseKey];
        completion(nil, TranslateError(TranslateErrorTypeAPI, message ?: @"翻译失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:TranslateErrorRequestErrorKey];
        completion(nil, TranslateError(TranslateErrorTypeNetwork, @"翻译失败", reqDict));
    }];
}

#pragma mark - 重写父类方法

- (EDQueryType)queryType {
    return EDQueryTypeBaidu;
}

- (NSString *)identifier {
    return @"Baidu";
}

- (NSString *)name {
    return @"百度翻译";
}

- (NSString *)link {
    return kBaiduRootPage;
}

- (MMOrderedDictionary *)supportLanguagesDictionary {
    return [[MMOrderedDictionary alloc] initWithKeysAndObjects:
            @(Language_auto), @"auto", @(Language_zh_Hans), @"zh", @(Language_zh_Hant), @"cht", @(Language_en), @"en", @(Language_yue), @"yue", @(Language_wyw), @"wyw", @(Language_ja), @"jp", @(Language_ko), @"kor", @(Language_fr), @"fra", @(Language_es), @"spa", @(Language_th), @"th", @(Language_ar), @"ara", @(Language_ru), @"ru", @(Language_pt), @"pt", @(Language_de), @"de", @(Language_it), @"it", @(Language_el), @"el", @(Language_nl), @"nl", @(Language_pl), @"pl", @(Language_bg), @"bul", @(Language_et), @"est", @(Language_da), @"dan", @(Language_fi), @"fin", @(Language_cs), @"cs", @(Language_ro), @"rom", @(Language_sl), @"slo", @(Language_sv), @"swe", @(Language_hu), @"hu", @(Language_vi), @"vie", nil];
}

- (void)translate:(NSString *)text from:(Language)from to:(Language)to completion:(nonnull void (^)(TranslateResult *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, TranslateError(TranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    void (^request)(void) = ^(void) {
        void (^translate)(Language f) = ^(Language f) {
            Language toLang = to;
            if (toLang == Language_auto) {
                toLang = (f == Language_zh_Hans || f == Language_zh_Hant) ? Language_en : Language_zh_Hans;
            }
            
            [self sendTranslateRequest:text from:f to:toLang completion:completion];
        };
        
        if (from == Language_auto) {
            [self detect:text completion:^(Language lang, NSError *_Nullable error) {
                if (error) {
                    completion(nil, error);
                    return;
                }
                translate(lang);
            }];
        } else {
            translate(from);
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

- (void)detect:(NSString *)text completion:(nonnull void (^)(Language, NSError *_Nullable))completion {
    if (!text.length) {
        completion(Language_auto, TranslateError(TranslateErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }
    
    // 字符串太长会导致获取语言的接口报错
    NSString *queryString = text;
    if (queryString.length >= 73) {
        queryString = [queryString substringToIndex:73];
    }
    
    NSString *url = [kBaiduRootPage stringByAppendingString:@"/langdetect"];
    NSDictionary *params = @{@"query" : queryString};
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, TranslateErrorRequestURLKey, params, TranslateErrorRequestParamKey, nil];
    
    mm_weakify(self);
    [self.jsonSession POST:[kBaiduRootPage stringByAppendingString:@"/langdetect"] parameters:@{@"query" : queryString} progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        mm_strongify(self);
        [reqDict setObject:responseObject ?: [NSNull null] forKey:TranslateErrorRequestResponseKey];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *jsonResult = responseObject;
            NSString *from = [jsonResult objectForKey:@"lan"];
            if ([from isKindOfClass:NSString.class] && from.length) {
                completion([self languageEnumFromString:from], nil);
            } else {
                completion(Language_auto, TranslateError(TranslateErrorTypeUnsupportLanguage, nil, reqDict));
            }
            return;
        }
        completion(Language_auto, TranslateError(TranslateErrorTypeAPI, @"判断语言失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:TranslateErrorRequestErrorKey];
        completion(Language_auto, TranslateError(TranslateErrorTypeNetwork, @"判断语言失败", reqDict));
    }];
}

- (void)audio:(NSString *)text from:(Language)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, TranslateError(TranslateErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }
    
    if (from == Language_auto) {
        [self detect:text completion:^(Language lang, NSError *_Nullable error) {
            if (!error) {
                completion([self getAudioURLWithText:text language:[self languageStringFromEnum:lang]], nil);
            } else {
                completion(nil, error);
            }
        }];
    } else {
        completion([self getAudioURLWithText:text language:[self languageStringFromEnum:from]], nil);
    }
}

- (NSString *)getAudioURLWithText:(NSString *)text language:(NSString *)language {
    return [NSString stringWithFormat:@"%@/gettts?lan=%@&text=%@&spd=3&source=web", kBaiduRootPage, language, text.mm_urlencode];
}

- (void)ocr:(NSImage *)image from:(Language)from to:(Language)to completion:(void (^)(OCRResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, TranslateError(TranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    
    NSData *data = [image mm_PNGData];
    NSString *fromLang = (from == Language_auto) ? [self languageStringFromEnum:Language_en] : [self languageStringFromEnum:from];
    NSString *toLang = nil;
    if (to == Language_auto) {
        toLang = (from == Language_zh_Hans || from == Language_zh_Hant) ? [self languageStringFromEnum:Language_en] : [self languageStringFromEnum:Language_zh_Hans];
    } else {
        toLang = [self languageStringFromEnum:to];
    }
    
    NSString *url = [kBaiduRootPage stringByAppendingPathComponent:@"/getocr"];
    NSDictionary *params = @{
        @"image" : data,
        @"from" : fromLang,
        @"to" : toLang
    };
    // 图片 base64 字符串过长，暂不打印
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, TranslateErrorRequestURLKey, @{@"from" : fromLang, @"to" : toLang}, TranslateErrorRequestParamKey, nil];
    
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
                    OCRResult *result = [OCRResult new];
                    NSString *from = [data objectForKey:@"from"];
                    if (from && [from isKindOfClass:NSString.class]) {
                        result.from = [self languageEnumFromString:from];
                    }
                    NSString *to = [data objectForKey:@"to"];
                    if (to && [to isKindOfClass:NSString.class]) {
                        result.to = [self languageEnumFromString:to];
                    }
                    NSArray<NSString *> *src = [data objectForKey:@"src"];
                    if (src && src.count) {
                        result.texts = [src mm_map:^id _Nullable(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            if ([obj isKindOfClass:NSString.class] && obj.length) {
                                OCRText *text = [OCRText new];
                                text.text = obj;
                                return text;
                            }
                            return nil;
                        }];
                    }
                    result.raw = responseObject;
                    if (result.texts.count) {
                        // 百度翻译按图片中的行进行分割，可能是一句话，所以用空格拼接
                        result.mergedText = [NSString mm_stringByCombineComponents:[result.texts mm_map:^id _Nullable(OCRText *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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
        [reqDict setObject:responseObject ?: [NSNull null] forKey:TranslateErrorRequestResponseKey];
        completion(nil, TranslateError(TranslateErrorTypeAPI, message ?: @"识别图片文本失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:TranslateErrorRequestErrorKey];
        completion(nil, TranslateError(TranslateErrorTypeNetwork, @"识别图片文本失败", reqDict));
    }];
}

- (void)ocrAndTranslate:(NSImage *)image from:(Language)from to:(Language)to ocrSuccess:(void (^)(OCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(OCRResult *_Nullable, TranslateResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, nil, TranslateError(TranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    mm_weakify(self);
    [self ocr:image from:from to:to completion:^(OCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        mm_strongify(self);
        if (ocrResult) {
            ocrSuccess(ocrResult, YES);
            [self translate:ocrResult.mergedText from:from to:to completion:^(TranslateResult *_Nullable result, NSError *_Nullable error) {
                completion(ocrResult, result, error);
            }];
        } else {
            completion(nil, nil, error);
        }
    }];
}

@end
