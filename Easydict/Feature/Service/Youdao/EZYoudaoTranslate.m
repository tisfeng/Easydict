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
#import <JavaScriptCore/JavaScriptCore.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "FWEncryptorAES.h"
#import <WebKit/WebKit.h>
#import "NSData+EZMD5.h"
#import "EZNetworkManager.h"
#import "NSArray+EZChineseText.h"
#import "EZConfiguration.h"

static NSString *const kYoudaoTranslatetURL = @"https://fanyi.youdao.com";
static NSString *const kYoudaoDictURL = @"https://dict.youdao.com";

@interface EZYoudaoTranslate ()

@property (nonatomic, strong) AFHTTPSessionManager *jsonSession;
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) EZWebViewTranslator *webViewTranslator;

@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic, strong) JSValue *jsFunction;
@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) EZNetworkManager *networkManager;

@property (nonatomic, copy) NSString *cookie;

@end


@implementation EZYoudaoTranslate

- (instancetype)init {
    if (self = [super init]) {
        // Youdao's cookie seems to have a long expiration date, so we don't need to update them frequently.
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

- (EZNetworkManager *)networkManager {
    if (!_networkManager) {
        _networkManager = [[EZNetworkManager alloc] init];
    }
    return _networkManager;
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

- (JSContext *)jsContext {
    if (!_jsContext) {
        JSContext *jsContext = [JSContext new];
        NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"youdao-sign" ofType:@"js"];
        NSString *jsString = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
        // 加载方法
        [jsContext evaluateScript:jsString];
        _jsContext = jsContext;
    }
    return _jsContext;
}

- (JSValue *)jsFunction {
    if (!_jsFunction) {
        _jsFunction = [self.jsContext objectForKeyedSubscript:@"decrypt"];
    }
    return _jsFunction;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKPreferences *preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = NO;
        configuration.preferences = preferences;
        
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"js"];
        [webView loadFileURL:URL allowingReadAccessToURL:URL];
        
        _webView = webView;
    }
    return _webView;
}

- (NSString *)cookie {
    NSString *cookie = [NSUserDefaults mm_read:kYoudaoTranslatetURL];
    if (!cookie) {
        cookie = @"OUTFOX_SEARCH_USER_ID=833782676@113.88.171.235; domain=.youdao.com; expires=2052-12-31 13:12:38 +0000";
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
    EZQueryTextType type = [EZConfiguration.shared intelligentQueryTextTypeForServiceType:self.serviceType];
    return type;
}

- (NSString *)name {
    return NSLocalizedString(@"youdao_dict", nil);
}

- (NSString *)link {
    return @"http://fanyi.youdao.com";
}

/**
 Youdao word link, support 4 languages: en, ja, ko, fr, and to Chinese. https://www.youdao.com/result?word=good&lang=en
 
 means: en <-> zh-CHS, ja <-> zh-CHS, ko <-> zh-CHS, fr <-> zh-CHS, if language not in this list, then return nil.
 */
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *encodedWord = [queryModel.inputText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
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

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    if (!text.length) {
        completion(self.result, EZTranslateError(EZErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:NO from:from to:to completion:completion]) {
        return;
    }
    
    [self setDidFinishBlock:^(EZQueryResult *result, NSError *error) {
        NSArray *texts = result.translatedResults;
        result.translatedResults = texts;
    }];
    
    void (^callback)(EZQueryResult *result, NSError *error) = ^(EZQueryResult *result, NSError *error) {
        self.didFinishBlock(result, error);
        completion(result, error);
    };
    
    [self queryYoudaoDictAndTranslation:text from:from to:to completion:callback];
}

- (void)detectText:(NSString *)text completion:(void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto, EZTranslateError(EZErrorTypeParam, @"识别语言的文本为空", nil));
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
        completion(nil, EZTranslateError(EZErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }
    //    [super textToAudio:text fromLanguage:from completion:completion];
    
    /**
     It seems that the Youdao TTS audio will auto trim to 600 chars.
     https://dict.youdao.com/dictvoice?audio=Ukraine%20may%20get%20another%20Patriot%20battery.&le=en
     
     Sogou language codes are the same as Youdaos.
     https://fanyi.sogou.com/reventondc/synthesis?text=class&speed=1&lang=enS&from=translateweb&speaker=6
     */
    
    NSString *language = [self getTTSLanguageCode:from];
    
    //    text = [text trimToMaxLength:1000];
    text = [text mm_urlencode]; // text.mm_urlencode
    
    NSString *audioURL = [NSString stringWithFormat:@"%@/dictvoice?audio=%@&le=%@", kYoudaoDictURL, text, language];
    //    audioURL = [NSString stringWithFormat:@"https://fanyi.sogou.com/reventondc/synthesis?text=%@&speed=1&lang=%@&from=translateweb&speaker=6", text, language];
    
    completion(audioURL, nil);
}

- (void)ocr:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZOCRResult *_Nullable result, NSError *_Nullable error))completion {
    if (!image) {
        completion(nil, EZTranslateError(EZErrorTypeParam, @"图片为空", nil));
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
        completion(nil, EZTranslateError(EZErrorTypeAPI, message ?: @"图片翻译失败", reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, EZTranslateError(EZErrorTypeNetwork, @"图片翻译失败", reqDict));
    }];
}

- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable, EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, nil, EZTranslateError(EZErrorTypeParam, @"图片为空", nil));
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

- (void)queryYoudaoDictAndTranslation:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    if (!text.length) {
        completion(self.result, EZTranslateError(EZErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    if (self.queryTextType == EZQueryTextTypeNone) {
        self.result.errorMessage = NSLocalizedString(@"no_results_found", nil);
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
    
    BOOL enableTranslation = self.queryTextType & EZQueryTextTypeTranslation;
    if (enableTranslation) {
        // 2.Query Youdao translate.
        dispatch_group_enter(group);
        [self webTranslate:text from:from to:to completion:^(EZQueryResult *_Nullable result, NSError *_Nullable error) {
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

/// Query Youdao dict, unofficial API
- (void)queryYoudaoDict:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    if (!text.length) {
        completion(self.result, EZTranslateError(EZErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    if (self.queryTextType == EZQueryTextTypeNone) {
        completion(self.result, nil);
        return;
    }
    
    BOOL enableDictionary = self.queryTextType & EZQueryTextTypeDictionary;
    
    // Youdao dict can query word, phrase, even short text.
    BOOL shouldQueryDictionary = [EZTextWordUtils shouldQueryDictionary:text language:from];
    
    NSString *foreignLangauge = [self youdaoDictForeignLangauge:self.queryModel];
    BOOL supportQueryDictionaryLanguage = foreignLangauge != nil;
    
    // If Youdao Dictionary does not support the language, try querying translate API.
    if (!enableDictionary || !supportQueryDictionaryLanguage || !shouldQueryDictionary) {
        self.result.errorMessage = NSLocalizedString(@"no_results_found", nil);
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
                MMLogInfo(@"有道翻译接口数据解析异常 %@", exception);
                message = @"有道翻译接口数据解析异常";
            }
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        self.result.error = EZTranslateError(EZErrorTypeAPI, message, reqDict);
        completion(self.result, self.result.error);
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        self.result.error = EZTranslateError(EZErrorTypeNetwork, nil, reqDict);
        completion(self.result, self.result.error);
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}


/// Youdao web translate API,
/// !!!: Deprecated, 2023.5
- (void)youdaoWebTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    NSString *fromLanguage = [self languageCodeForLanguage:from];
    NSString *toLanguage = [self languageCodeForLanguage:to];
    
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
        @"Cookie" : self.cookie,
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
                NSArray *texts = [self parseTranslateResult:dict];
                self.result.translatedResults = texts;
                completion(self.result, nil);
                return;
            }
        }
        completion(self.result, EZTranslateError(EZErrorTypeAPI, @"翻译失败", responseObject));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        completion(self.result, EZTranslateError(EZErrorTypeNetwork, nil, error));
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
        completion(self.result, EZTranslateError(EZErrorTypeParam, @"翻译的文本为空", nil));
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
                        
                        EZLanguage language = result.queryModel.queryFromLanguage;
                        // 解析音频
                        NSMutableArray *phoneticArray = [NSMutableArray array];
                        if (basic.us_phonetic && basic.us_speech) {
                            EZWordPhonetic *phonetic = [EZWordPhonetic new];
                            phonetic.name = NSLocalizedString(@"us_phonetic", nil);
                            phonetic.language = language;
                            phonetic.accent = @"us";
                            phonetic.value = basic.us_phonetic;
                            phonetic.speakURL = basic.us_speech;
                            [phoneticArray addObject:phonetic];
                        }
                        if (basic.uk_phonetic && basic.uk_speech) {
                            EZWordPhonetic *phonetic = [EZWordPhonetic new];
                            phonetic.name = NSLocalizedString(@"uk_phonetic", nil);
                            phonetic.language = language;
                            phonetic.accent = @"uk";
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
                                        NSLog(@"有道翻译手动拆词 %@", obj);
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
                                            NSLog(@"有道翻译手动拆词 %@", text);
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
                            BOOL hasEnglishWordAudioURL = [result.from isEqualToString:EZLanguageEnglish] && [result.to isEqualToString:EZLanguageSimplifiedChinese] && wordResult.phonetics.firstObject.speakURL.length;
                            if (hasEnglishWordAudioURL) {
                                result.fromSpeakURL = wordResult.phonetics.firstObject.speakURL;
                            }
                        }
                    }
                    
                    // 解析普通释义
                    NSMutableArray *normalResults = [NSMutableArray array];
                    [response.translation enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                        [normalResults addObject:obj];
                    }];
                    result.translatedResults = normalResults.count ? normalResults.copy : nil;
                    
                    // 原始数据
                    result.raw = responseObject;
                    
                    if (result.wordResult || result.translatedResults) {
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
        completion(self.result, EZTranslateError(EZErrorTypeAPI, message ?: nil, reqDict));
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(self.result, EZTranslateError(EZErrorTypeNetwork, nil, reqDict));
    }];
}

// Get youdao fanyi cookie, and save it to user defaults.
- (void)requestYoudaoCookie {
    // https://fanyi.youdao.com/index.html#/
    NSString *cookieURL = [NSString stringWithFormat:@"%@/index.html#/", kYoudaoTranslatetURL];
    [self.networkManager requestCookieOfURL:cookieURL cookieName:@"OUTFOX_SEARCH_USER_ID" completion:^(NSString *cookie) {
        if (cookie.length) {
            [NSUserDefaults mm_write:cookie forKey:kYoudaoTranslatetURL];
        }
    }];
}

#pragma mark - WebView Translate

- (void)webViewTranslate:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *wordLink = [self wordLink:self.queryModel];
    if (!wordLink) {
        NSError *error = EZTranslateError(EZErrorTypeUnsupportedLanguage, nil, nil);
        completion(self.result, error);
        return;
    }
    
    [self.webViewTranslator queryTranslateURL:wordLink completionHandler:^(NSArray<NSString *> *texts, NSError *error) {
        self.result.translatedResults = texts;
        completion(self.result, error);
    }];
    
    mm_weakify(self);
    [self.queryModel setStopBlock:^{
        mm_strongify(self);
        [self.webViewTranslator resetWebView];
    } serviceType:self.serviceType];
}


#pragma mark - New Web Translate, 2023.5

/// New Youdao web translate && dict API, Ref: https://github.com/Chen03/StaticeApp/blob/a8706aaf4806468a663d7986b901b09be5fc9319/Statice/Model/Search/Youdao.swift
- (void)webTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    NSString *client = @"fanyideskweb";
    NSString *product = @"webfanyi";
    NSString *key = @"fsdsogkndfokasodnaso";
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
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.requestSerializer = requestSerializer;
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
        [self webViewTranslate:completion];
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
    
    NSString *decryptedText = [FWEncryptorAES decryptStrFromBase64:encryptedText Key:keyDataMD5Data IV:ivDataMD5Data];
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
