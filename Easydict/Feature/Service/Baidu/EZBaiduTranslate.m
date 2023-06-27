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
#import "EZWebViewTranslator.h"
#import "EZNetworkManager.h"
#import "EZConfiguration.h"

static NSString *const kBaiduTranslateURL = @"https://fanyi.baidu.com";

@interface EZBaiduTranslate ()

@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic, strong) JSValue *jsFunction;
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) AFHTTPSessionManager *jsonSession;

@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *gtk;
@property (nonatomic, assign) NSInteger error997Count;

@property (nonatomic, strong) EZWebViewTranslator *webViewTranslator;

@property (nonatomic, strong) EZNetworkManager *networkManager;

@property (nonatomic, copy) NSString *cookie;

@end


@implementation EZBaiduTranslate

- (instancetype)init {
    if (self = [super init]) {
        [self updateCookieAndToken];
    }
    return self;
}

- (EZWebViewTranslator *)webViewTranslator {
    if (!_webViewTranslator) {
        NSString *selector = @"p.ordinary-output.target-output.clearfix";
        _webViewTranslator = [[EZWebViewTranslator alloc] init];
        _webViewTranslator.querySelector = selector;
    }
    return _webViewTranslator;
}

- (EZNetworkManager *)networkManager {
    if (!_networkManager) {
        _networkManager = [[EZNetworkManager alloc] init];
    }
    return _networkManager;
}

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
        _jsFunction = [self.jsContext objectForKeyedSubscript:@"encrypt"];
    }
    return _jsFunction;
}

- (AFHTTPSessionManager *)htmlSession {
    if (!_htmlSession) {
        AFHTTPSessionManager *htmlSession = [AFHTTPSessionManager manager];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
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
        jsonSession.requestSerializer = requestSerializer;
        AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
        jsonSession.responseSerializer = responseSerializer;

        _jsonSession = jsonSession;
    }
    return _jsonSession;
}

- (NSString *)cookie {
    NSString *cookie = [[NSUserDefaults standardUserDefaults] stringForKey:kBaiduTranslateURL] ?: @"BAIDUID=0F8E1A72A51EE47B7CA0A81711749C00:FG=1;";
    return cookie;
}

#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeBaidu;
}

- (EZQueryTextType)queryTextType {
    EZQueryTextType defaultType = EZQueryTextTypeDictionary | EZQueryTextTypeSentence | EZQueryTextTypeTranslation;
    EZQueryTextType type = [EZConfiguration.shared queryTextTypeForServiceType:self.serviceType];
    if (type == 0) {
        type = defaultType;
    }
    return type;
}

- (EZQueryTextType)intelligentQueryTextType {
    EZQueryTextType type = [EZConfiguration.shared intelligentQueryTextTypeForServiceType:self.serviceType];
    return type;
}

- (NSString *)name {
    return NSLocalizedString(@"baidu_translate", nil);
}

- (NSString *)link {
    return kBaiduTranslateURL;
}

// https://fanyi.baidu.com/#en/zh/good
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *from = [self languageCodeForLanguage:queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:queryModel.queryTargetLanguage];
    NSString *text = [queryModel.inputText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    return [NSString stringWithFormat:@"%@/#%@/%@/%@", kBaiduTranslateURL, from, to, text];
}

// get supportLanguagesDictionary, key is EZLanguage, value is NLLanguage, such as EZLanguageAuto, NLLanguageUndetermined
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                                                        EZLanguageAuto, @"auto",
                                                                        EZLanguageSimplifiedChinese, @"zh",
                                                                        EZLanguageClassicalChinese, @"wyw",
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
                                                                        EZLanguageLithuanian, @"lit",
                                                                        EZLanguageLatvian, @"lav",
                                                                        EZLanguageUkrainian, @"ukr",
                                                                        EZLanguageBulgarian, @"bul",
                                                                        EZLanguageIndonesian, @"id",
                                                                        EZLanguageMalay, @"msa",
                                                                        EZLanguageSlovenian, @"slv",
                                                                        EZLanguageEstonian, @"est",
                                                                        EZLanguageVietnamese, @"vie",
                                                                        EZLanguagePersian, @"per",
                                                                        EZLanguageHindi, @"hin",
                                                                        EZLanguageTelugu, @"tel",
                                                                        EZLanguageTamil, @"tam",
                                                                        EZLanguageUrdu, @"urd",
                                                                        EZLanguageFilipino, @"fil",
                                                                        EZLanguageKhmer, @"khm",
                                                                        EZLanguageLao, @"lo",
                                                                        EZLanguageBengali, @"ben",
                                                                        EZLanguageBurmese, @"bur",
                                                                        EZLanguageNorwegian, @"nor",
                                                                        EZLanguageSerbian, @"srp",
                                                                        EZLanguageCroatian, @"hrv",
                                                                        EZLanguageMongolian, @"mon",
                                                                        EZLanguageHebrew, @"heb",
                                                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(self.result, EZTranslateError(EZErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:NO from:from to:to completion:completion]) {
        return;
    }
    
    text = [text trimToMaxLength:5000];
    
    void (^request)(void) = ^(void) {
        void (^translateBlock)(EZLanguage) = ^(EZLanguage from) {
            [self sendTranslateRequest:text from:from to:to completion:completion];
        };
        
        if ([from isEqualToString:EZLanguageAuto]) {
            [self detectText:text completion:^(EZLanguage lang, NSError *_Nullable error) {
                if (error) {
                    completion(self.result, error);
                    return;
                }
                translateBlock(lang);
            }];
        } else {
            translateBlock(from);
        }
    };
    
    if (!self.token || !self.gtk) {
        NSLog(@"get Baidu token and gtk");
        mm_weakify(self);
        [self sendGetTokenAndGtkRequestWithCompletion:^(NSString *token, NSString *gtk, NSError *error) {
            mm_strongify(self)
            NSLog(@"Baidu token: %@, gtk: %@", token, gtk);
            if (!error && (!token || !gtk)) {
                error = [EZTranslateError errorWithString:@"Get token failed."];
            }
            if (error) {
                completion(self.result, error);
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

- (void)detectText:(NSString *)text completion:(nonnull void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto, EZTranslateError(EZErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }

    // 字符串太长会导致获取语言的接口报错
    NSString *queryString = [text trimToMaxLength:73];

    NSString *url = [kBaiduTranslateURL stringByAppendingString:@"/langdetect"];
    NSDictionary *params = @{@"query" : queryString};
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params, EZTranslateErrorRequestParamKey, nil];

    mm_weakify(self);
    [self.jsonSession POST:url parameters:@{@"query" : queryString} progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        mm_strongify(self);
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *jsonResult = responseObject;
            NSString *from = [jsonResult objectForKey:@"lan"];
            NSLog(@"Baidu detect language: %@", from);

            if ([from isKindOfClass:NSString.class] && from.length) {
                completion([self languageEnumFromCode:from], nil);
            } else {
                completion(EZLanguageAuto, EZTranslateError(EZErrorTypeUnsupportedLanguage, nil, reqDict));
            }
            return;
        }
        completion(EZLanguageAuto, EZTranslateError(EZErrorTypeAPI, @"判断语言失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(EZLanguageAuto, EZTranslateError(EZErrorTypeNetwork, @"判断语言失败", reqDict));
    }];
}

- (void)textToAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, EZTranslateError(EZErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }

    if ([from isEqualToString:EZLanguageAuto]) {
        [self detectText:text completion:^(EZLanguage lang, NSError *_Nullable error) {
            if (!error) {
                completion([self getAudioURLWithText:text language:[self getTTSLanguageCode:lang]], nil);
            } else {
                completion(nil, error);
            }
        }];
    } else {
        completion([self getAudioURLWithText:text language:[self getTTSLanguageCode:from]], nil);
    }
}

- (NSString *)getAudioURLWithText:(NSString *)text language:(NSString *)language {
    /**
     ???: As far as I tested, the max length of text is ~1000.
     !!!: This audio url sometimes cannot be played, Baidu web audio is not reliable.
     
     https://fanyi.baidu.com/gettts?lan=en&text=good&spd=4&source=web
     */
    
    text = [text trimToMaxLength:1000];
    text = [text mm_urlencode]; // text.mm_urlencode
    NSString *audioURL = [NSString stringWithFormat:@"%@/gettts?lan=%@&text=%@&spd=4&source=web", kBaiduTranslateURL, language, text];
    return audioURL;
}

- (void)ocr:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, EZTranslateError(EZErrorTypeParam, @"图片为空", nil));
        return;
    }

    NSData *data = [image mm_PNGData];
    NSString *fromLang = ([from isEqualToString:EZLanguageAuto]) ? [self languageCodeForLanguage:EZLanguageEnglish] : [self languageCodeForLanguage:from];
    NSString *toLang = nil;
    if ([to isEqualToString:EZLanguageAuto]) {
        toLang = [EZLanguageManager.shared userTargetLanguageWithSourceLanguage:from];
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
        completion(nil, EZTranslateError(EZErrorTypeAPI, message ?: @"识别图片文本失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, EZTranslateError(EZErrorTypeNetwork, @"识别图片文本失败", reqDict));
    }];
}

- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable, EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, nil, EZTranslateError(EZErrorTypeParam, @"图片为空", nil));
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

#pragma mark - Web translate API

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
    
    NSDictionary *headers = @{
        @"User-Agent" : EZUserAgent,
        @"Content-Type" : @"application/x-www-form-urlencoded; charset=UTF-8",
        @"Cookie" : self.cookie,
    };
    
    // set headers
    for (NSString *key in headers.allKeys) {
        [self.jsonSession.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
    }

    NSURLSessionTask *task = [self.jsonSession POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        [self parseResponseObject:responseObject completion:completion];
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params, EZTranslateErrorRequestParamKey, nil];
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(self.result, EZTranslateError(EZErrorTypeNetwork, nil, reqDict));
    }];

    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}

// TODO: need to optimize the results of Baidu query words.
- (void)parseResponseObject:(id _Nullable)responseObject completion:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if ([self.queryModel isServiceStopped:self.serviceType]) {
        return;
    }
    
    EZQueryResult *result = self.result;
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionary];

    NSString *text = self.queryModel.inputText;
    NSString *from = self.queryModel.queryFromLanguage;
    NSString *to = self.queryModel.queryTargetLanguage;

    NSString *message = nil;
    if (responseObject) {
        @try {
            EZBaiduTranslateResponse *response = [EZBaiduTranslateResponse mj_objectWithKeyValues:responseObject];
            if (response) {
                if (response.error == 0) {
                    self.error997Count = 0;

                    result.queryText = text;
                    result.from = [self languageEnumFromCode:response.trans_result.from] ?: from;
                    result.to = [self languageEnumFromCode:response.trans_result.to] ?: to;

                    // 解析单词释义
                    [response.dict_result.simple_means mm_anyPut:^(EZBaiduTranslateResponseSimpleMean *_Nonnull simple_means) {
                        EZTranslateWordResult *wordResult = [EZTranslateWordResult new];
                        NSMutableArray *tags = [NSMutableArray arrayWithArray:simple_means.tags.core];
                        for (NSString *tag in simple_means.tags.other) {
                            if (tag.length) {
                                [tags addObject:tag];
                            }
                        }
                        wordResult.tags = tags;
                        
                        [simple_means.symbols.firstObject mm_anyPut:^(EZBaiduTranslateResponseSymbol *_Nonnull symbol) {
                            // 解析音标
                            NSMutableArray *phonetics = [NSMutableArray array];
                            EZLanguage language = self.queryModel.queryFromLanguage;
                            
                            if (symbol.ph_am.length) {
                                [phonetics addObject:[EZWordPhonetic mm_anyMake:^(EZWordPhonetic *_Nonnull obj) {
                                    obj.name = NSLocalizedString(@"us_phonetic", nil);
                                    obj.language = language;
                                    obj.accent = @"us";
                                    obj.word = text;
                                    obj.value = symbol.ph_am;
                                    obj.speakURL = [self getAudioURLWithText:result.queryText language:@"en"];
                                }]];
                            }
                            if (symbol.ph_en.length) {
                                [phonetics addObject:[EZWordPhonetic mm_anyMake:^(EZWordPhonetic *_Nonnull obj) {
                                    obj.name = NSLocalizedString(@"uk_phonetic", nil);
                                    obj.language = language;
                                    obj.accent = @"uk";
                                    obj.word = text;
                                    obj.value = symbol.ph_en;
                                    obj.speakURL = [self getAudioURLWithText:result.queryText language:@"uk"];
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
                                               obj.name = NSLocalizedString(@"singular", nil);
                                               obj.words = exchange.word_third;
                                           }]];
                            }
                            if (exchange.word_pl.count) {
                                [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                               obj.name = NSLocalizedString(@"plural", nil);
                                               obj.words = exchange.word_pl;
                                           }]];
                            }
                            if (exchange.word_er.count) {
                                [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                               obj.name = NSLocalizedString(@"comparative", nil);
                                               obj.words = exchange.word_er;
                                           }]];
                            }
                            if (exchange.word_est.count) {
                                [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                               obj.name = NSLocalizedString(@"superlative", nil);
                                               obj.words = exchange.word_est;
                                           }]];
                            }
                            if (exchange.word_past.count) {
                                [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                               obj.name = NSLocalizedString(@"past", nil);
                                               obj.words = exchange.word_past;
                                           }]];
                            }
                            if (exchange.word_done.count) {
                                [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                               obj.name = NSLocalizedString(@"past_participle", nil);
                                               obj.words = exchange.word_done;
                                           }]];
                            }
                            if (exchange.word_ing.count) {
                                [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                               obj.name = NSLocalizedString(@"present_participle", nil);
                                               obj.words = exchange.word_ing;
                                           }]];
                            }
                            if (exchange.word_proto.count) {
                                [exchanges addObject:[EZTranslateExchange mm_anyMake:^(EZTranslateExchange *_Nonnull obj) {
                                               obj.name = NSLocalizedString(@"root", nil);
                                               obj.words = exchange.word_proto;
                                           }]];
                            }
                            wordResult.exchanges = exchanges.count ? exchanges.copy : nil;
                        }];

                        // 解析 simple_means["symbols"][0]["parts"][0]["means"]
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

                        // ???: use word_means as normalResults?
                        if (simple_means.word_means.count) {
                            result.translatedResults = @[ simple_means.word_means.firstObject.trim ];
                        }

                        // 至少要有词义或单词组才认为有单词翻译结果
                        if (wordResult.parts || wordResult.simpleWords) {
                            result.wordResult = wordResult;
                        }
                    }];


                    // 解析普通释义
                    NSMutableArray *translatedResults = [NSMutableArray array];
                    [response.trans_result.data enumerateObjectsUsingBlock:^(EZBaiduTranslateResponseData *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                        NSString *translatedText = obj.dst.trim;
                        if (obj.prefixWrap) {
                            translatedText = [NSString stringWithFormat:@"\n%@", translatedText];
                        }
                        [translatedResults addObject:translatedText];
                    }];

                    if (translatedResults.count) {
                        result.translatedResults = translatedResults.copy;
                    }

                    // 原始数据
                    result.raw = responseObject;

                    if (result.wordResult || result.translatedResults) {
                        completion(result, nil);
                        return;
                    }

                    message = @"百度翻译结果为空";

                    // If api failed, try to use webView query.
                    [self webViewTranslate:completion];

                    return;

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
                    message = [NSString stringWithFormat:@"错误码 %zd", response.error];
                }
            }
        } @catch (NSException *exception) {
            MMLogInfo(@"百度翻译接口数据解析异常 %@", exception);
            message = @"百度翻译接口数据解析异常";
        }
    }
    
    // If error, update cookie.
    [self updateCookieAndToken];

    NSError *error = EZTranslateError(EZErrorTypeAPI, message ?: nil, reqDict);
    MMLogInfo(@"baidu API error: %@", error);

    [self webViewTranslate:completion];

    //    [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
    //    completion(self.result, error);
}

/// Get token, gtk
- (void)sendGetTokenAndGtkRequestWithCompletion:(void (^)(NSString *_Nullable token, NSString *_Nullable gtk, NSError *error))completion {
    NSString *url = kBaiduTranslateURL;
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObject:url forKey:EZTranslateErrorRequestURLKey];
    
    NSDictionary *headers = @{
        @"Cookie" : self.cookie,
    };
    
    // set headers
    for (NSString *key in headers.allKeys) {
        [self.jsonSession.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
    }
    
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
            completion(nil, nil, EZTranslateError(EZErrorTypeAPI, @"获取 token 失败", reqDict));
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, nil, EZTranslateError(EZErrorTypeNetwork, @"获取 token 失败", reqDict));
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

/// Update cookie and token.
- (void)updateCookieAndToken {
    [self.networkManager requestCookieOfURL:kBaiduTranslateURL cookieName:@"BAIDUID" completion:^(NSString *cookie) {
        if (cookie.length) {
            [NSUserDefaults mm_write:cookie forKey:kBaiduTranslateURL];
        }
        
        [self sendGetTokenAndGtkRequestWithCompletion:^(NSString *token, NSString *gtk, NSError *error) {
            NSLog(@"Baidu token: %@, gtk: %@", token, gtk);
            if (!error && (!token || !gtk)) {
                error = [EZTranslateError errorWithString:@"Get token failed."];
            }

            self.token = token;
            self.gtk = gtk;
        }];
    }];
}

#pragma mark - WebView Translate.

- (void)webViewTranslate:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *monitorURL = @"https://fanyi.baidu.com/v2transapi";
    [self.webViewTranslator monitorBaseURLString:monitorURL
                                         loadURL:[self wordLink:self.queryModel]
                               completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }
        
        if (error) {
            completion(self.result, error);
            return;
        }
        
        [self parseResponseObject:responseObject completion:completion];
    }];
    
    mm_weakify(self);
    [self.queryModel setStopBlock:^{
        mm_strongify(self);
        [self.webViewTranslator resetWebView];
    } serviceType:self.serviceType];
}

@end
