//
//  EZGoogleTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZGoogleTranslate.h"
#import "EZYoudaoTranslate.h"
#import <JavaScriptCore/JavaScriptCore.h>

#define kGoogleRootPage(isCN) (isCN ? @"https://translate.google.cn" : @"https://translate.google.com")

static NSString *const kGoogleTranslateURL = @"https://translate.google.com";

@interface EZGoogleTranslate ()

@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic, strong) JSValue *signFunction;
@property (nonatomic, strong) JSValue *window;
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) AFHTTPSessionManager *jsonSession;
@property (nonatomic, strong) EZYoudaoTranslate *youdao;

@end

@implementation EZGoogleTranslate

- (JSContext *)jsContext {
    if (!_jsContext) {
        JSContext *jsContext = [JSContext new];
        NSString *jsPath =
        [[NSBundle mainBundle] pathForResource:@"google-translate-sign"
                                        ofType:@"js"];
        NSString *jsString = [NSString stringWithContentsOfFile:jsPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
        // 加载方法
        [jsContext evaluateScript:jsString];
        _jsContext = jsContext;
    }
    return _jsContext;
}
- (JSValue *)signFunction {
    if (!_signFunction) {
        _signFunction = [self.jsContext objectForKeyedSubscript:@"sign"];
    }
    return _signFunction;
}
- (JSValue *)window {
    if (!_window) {
        _window = [self.jsContext objectForKeyedSubscript:@"window"];
    }
    return _window;
}

- (AFHTTPSessionManager *)htmlSession {
    if (!_htmlSession) {
        AFHTTPSessionManager *htmlSession = [AFHTTPSessionManager manager];
        
        AFHTTPRequestSerializer *requestSerializer =
        [AFHTTPRequestSerializer serializer];
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

- (AFHTTPSessionManager *)jsonSession {
    if (!_jsonSession) {
        AFHTTPSessionManager *jsonSession = [AFHTTPSessionManager manager];
        
        AFHTTPRequestSerializer *requestSerializer =
        [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X "
         @"10_15_0) AppleWebKit/537.36 (KHTML, like "
         @"Gecko) Chrome/77.0.3865.120 Safari/537.36"
                 forHTTPHeaderField:@"User-Agent"];
        jsonSession.requestSerializer = requestSerializer;
        
        AFJSONResponseSerializer *responseSerializer =
        [AFJSONResponseSerializer serializer];
        responseSerializer.acceptableContentTypes =
        [NSSet setWithObjects:@"application/json", nil];
        jsonSession.responseSerializer = responseSerializer;
        
        _jsonSession = jsonSession;
    }
    return _jsonSession;
}

- (EZYoudaoTranslate *)youdao {
    if (!_youdao) {
        _youdao = [EZYoudaoTranslate new];
    }
    return _youdao;
}

#pragma mark -

- (void)sendGetTKKRequestWithCompletion:
(void (^)(NSString *_Nullable TKK, NSError *_Nullable error))completion {
    NSString *url = kGoogleRootPage(self.isCN);
    NSMutableDictionary *reqDict =
    [NSMutableDictionary dictionaryWithObject:url
                                       forKey:EZTranslateErrorRequestURLKey];
    
    [self.htmlSession GET:url
               parameters:nil
                 progress:nil
                  success:^(NSURLSessionDataTask *_Nonnull task,
                            id _Nullable responseObject) {
        __block NSString *tkkResult = nil;
        NSString *string = [[NSString alloc] initWithData:responseObject
                                                 encoding:NSUTF8StringEncoding];
        
        // tkk:'437961.2280157552'
        NSRegularExpression *tkkRegex = [NSRegularExpression
                                         regularExpressionWithPattern:@"tkk:'\\d+\\.\\d+',"
                                         options:NSRegularExpressionCaseInsensitive
                                         error:nil];
        NSArray<NSTextCheckingResult *> *tkkMatchResults =
        [tkkRegex matchesInString:string
                          options:NSMatchingReportCompletion
                            range:NSMakeRange(0, string.length)];
        [tkkMatchResults
         enumerateObjectsUsingBlock:^(NSTextCheckingResult *_Nonnull obj,
                                      NSUInteger idx, BOOL *_Nonnull stop) {
            NSString *tkk = [string substringWithRange:obj.range];
            if (tkk.length > 7) {
                tkkResult =
                [tkk substringWithRange:NSMakeRange(5, tkk.length - 7)];
            }
            *stop = YES;
        }];
        
        if (tkkResult.length) {
            completion(tkkResult, nil);
        } else {
            NSString *TKK = [[self.window objectForKeyedSubscript:@"TKK"] toString];
            if (TKK.length) {
                completion(TKK, nil);
                return;
            }
            
            [reqDict setObject:responseObject ?: [NSNull null]
                        forKey:EZTranslateErrorRequestResponseKey];
            completion(nil, EZTranslateError(EZTranslateErrorTypeAPI, @"谷歌翻译获取 tkk 失败", reqDict));
        }
    }
                  failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, EZTranslateError(EZTranslateErrorTypeAPI, @"谷歌翻译获取 tkk 失败", reqDict));
    }];
}

- (void)updateTKKWithCompletion:(void (^)(NSError *_Nullable error))completion {
    long long now = floor(NSDate.date.timeIntervalSince1970 / 3600);
    NSString *TKK = [[self.window objectForKeyedSubscript:@"TKK"] toString];
    NSArray<NSString *> *TKKComponents = [TKK componentsSeparatedByString:@"."];
    if (TKKComponents.firstObject.longLongValue == now) {
        completion(nil);
        return;
    }
    
    mm_weakify(self)
    
    [self sendGetTKKRequestWithCompletion:^(NSString *_Nullable TKK,
                                            NSError *_Nullable error) {
        mm_strongify(self) if (TKK) {
            [self.window setObject:TKK forKeyedSubscript:@"TKK"];
            completion(nil);
        }
        else {
            completion(error);
        }
    }];
}

- (void)sendTranslateSingleText:(NSString *)text
                           from:(EZLanguage)from
                             to:(EZLanguage)to
                     completion:
(void (^)(id _Nullable responseObject,
          NSString *_Nullable signText,
          NSMutableDictionary *reqDict,
          NSError *_Nullable error))completion {
    NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
    
    NSString *url = [kGoogleRootPage(self.isCN)
                     stringByAppendingPathComponent:@"/translate_a/single"];
    NSDictionary *params = @{
        @"q" : text,
        @"sl" : [self languageCodeForLanguage:from],
        @"tl" : [self languageCodeForLanguage:to],
        @"dt" : @"t",
        @"dj" : @"1",
        @"ie" : @"UTF-8",
        @"client" : @"gtx",
    };
    NSMutableDictionary *reqDict = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params,
                                    EZTranslateErrorRequestParamKey, nil];
    
    [self.jsonSession GET:url
               parameters:params
                 progress:nil
                  success:^(NSURLSessionDataTask *_Nonnull task,
                            id _Nullable responseObject) {
        if (responseObject) {
            completion(responseObject, sign, reqDict, nil);
        } else {
            completion(
                       nil, nil, nil,
                       EZTranslateError(EZTranslateErrorTypeAPI, @"翻译失败", reqDict));
        }
    }
                  failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(
                   nil, nil, nil,
                   EZTranslateError(EZTranslateErrorTypeNetwork, @"翻译失败", reqDict));
    }];
}

#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeGoogle;
}

- (NSString *)name {
    return @"Google 翻译";
}

- (NSString *)link {
    return kGoogleRootPage(self.isCN);
}

// https://translate.google.com/?sl=auto&tl=zh-CN&text=good&op=translate
- (NSString *)wordLink {
    NSString *from = [self languageCodeForLanguage:self.queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:self.queryModel.queryTargetLanguage];
    NSString *text = [self.queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    return [NSString stringWithFormat:@"%@/?sl=%@&tl=%@&text=%@&op=translate", kGoogleTranslateURL, from, to, text];
}


- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, @"auto",
                                        EZLanguageSimplifiedChinese, @"zh-CN",
                                        EZLanguageTraditionalChinese, @"zh-TW",
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

- (void)translate:(NSString *)text
             from:(EZLanguage)from
               to:(EZLanguage)to
       completion:(nonnull void (^)(EZQueryResult *_Nullable,
                                    NSError *_Nullable))completion {
    //    [self translateSingleText:text from:from to:to completion:completion];
    [self translateTKKText:text from:from to:to completion:completion];
}


- (void)translateSingleText:(NSString *)text
                       from:(EZLanguage)from
                         to:(EZLanguage)to
                 completion:(nonnull void (^)(EZQueryResult *_Nullable,
                                              NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil,
                   EZTranslateError(EZTranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    void (^translateBlock)(NSString *, EZLanguage, EZLanguage) =
    ^(
      NSString *text, EZLanguage langFrom, EZLanguage langTo) {
          [self
           sendTranslateSingleText:text
           from:langFrom
           to:langTo
           completion:^(id _Nullable responseObject,
                        NSString *_Nullable signText,
                        NSMutableDictionary *reqDict,
                        NSError *_Nullable error) {
              if (error) {
                  completion(nil, error);
                  return;
              }
              
              NSString *message = nil;
              if (responseObject &&
                  [responseObject
                   isKindOfClass:NSDictionary.class]) {
                  @try {
                      NSDictionary *responseDict = responseObject;
                      
                      NSString *googleFromString = responseDict[@"src"];
                      EZLanguage googleFrom = [self languageEnumFromCode:googleFromString];
                      EZLanguage googleTo = langTo;
                      
                      EZQueryResult *result = self.result;
                      
                      result.text = text;
                      result.from = googleFrom;
                      result.to = googleTo;
                      result.fromSpeakURL = [self getAudioURLWithText:text language:googleFromString sign:signText];
                      
                      // 普通释义
                      NSArray *sentences = responseDict[@"sentences"];
                      if (sentences &&
                          [sentences isKindOfClass:NSArray.class]) {
                          NSString *trans = sentences[0][@"trans"];
                          if (trans &&
                              [trans isKindOfClass:NSString.class]) {
                              result.normalResults = @[ trans ];
                              NSString *signTo = [[self.signFunction
                                                   callWithArguments:@[ trans ]] toString];
                              result.toSpeakURL = [self
                                                   getAudioURLWithText:trans
                                                   language:
                                                       [self
                                                        languageCodeForLanguage:
                                                            googleTo]
                                                   sign:signTo];
                          }
                      }
                      
                      if (result.wordResult || result.normalResults) {
                          completion(result, nil);
                          return;
                      }
                      
                  } @catch (NSException *exception) {
                      MMLogInfo(@"谷歌翻译接口数据解析异常 %@",
                                exception);
                      message = @"谷歌翻译接口数据解析异常";
                  }
              }
              [reqDict
               setObject:responseObject ?: [NSNull null]
               forKey:EZTranslateErrorRequestResponseKey];
              completion(nil,
                         EZTranslateError(EZTranslateErrorTypeAPI,
                                          message ?: @"翻译失败",
                                          reqDict));
          }];
      };
    
    if ([from isEqualToString:EZLanguageAuto]) {
        // 需要先识别语言，用于指定目标语言
        [self detect:text
          completion:^(EZLanguage detectedLanguage, NSError *_Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            translateBlock(text, detectedLanguage, to);
        }];
    } else {
        translateBlock(text, from, to);
    }
}

- (void)translateTKKText:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(self.result, EZTranslateError(EZTranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    EZQueryResult *result = self.result;
    
    void (^translateBlock)(NSString *, EZLanguage, EZLanguage) = ^(NSString *text, EZLanguage langFrom, EZLanguage langTo) {
        [self sendTranslateTKKText:text from:langFrom to:langTo completion:^(id _Nullable responseObject, NSString *_Nullable signText, NSMutableDictionary *reqDict, NSError *_Nullable error) {
            if (error) {
                completion(self.result, error);
                return;
            }
            
            NSString *message = nil;
            if (responseObject && [responseObject isKindOfClass:NSArray.class]) {
                @try {
                    NSArray *responseArray = responseObject;
                    
                    NSString *googleFromString = responseArray[2];
                    EZLanguage googleFrom = [self languageEnumFromCode:googleFromString];
                    EZLanguage googleTo = langTo;
                    
                    result.raw = responseObject;
                    result.text = text;
                    result.from = googleFrom;
                    result.to = googleTo;
                    result.fromSpeakURL = [self getAudioURLWithText:text language:googleFromString sign:signText];
                    
                    // 英文查词 中文查词
                    NSArray<NSArray *> *dictResult = responseArray[1];
                    if (dictResult && [dictResult isKindOfClass:NSArray.class]) {
                        EZTranslateWordResult *wordResult = [EZTranslateWordResult new];
                        
                        NSString *phoneticText = responseArray[0][1][3];
                        if (phoneticText) {
                            EZTranslatePhonetic *phonetic = [EZTranslatePhonetic new];
                            phonetic.name = @"美";
                            phonetic.value = phoneticText;
                            phonetic.speakURL = result.fromSpeakURL;
                            
                            wordResult.phonetics = @[ phonetic ];
                        }
                        
                        if ([googleFrom isEqualToString:EZLanguageEnglish] &&
                            ([googleTo isEqualToString:EZLanguageSimplifiedChinese] || [googleTo isEqualToString:EZLanguageTraditionalChinese])) {
                            // 英文查词
                            NSMutableArray *parts = [NSMutableArray array];
                            [dictResult enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                if (![obj isKindOfClass:NSArray.class]) {
                                    return;
                                }
                                EZTranslatePart *part = [EZTranslatePart new];
                                part.part = [obj firstObject];
                                part.means = [obj[1] mm_where:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                    return [obj isKindOfClass:NSString.class];
                                }];
                                if (part.means) {
                                    [parts addObject:part];
                                }
                            }];
                            if (parts.count) {
                                wordResult.parts = parts.copy;
                            }
                        } else if (([googleFrom isEqualToString:EZLanguageSimplifiedChinese]
                                    || [googleFrom isEqualToString:EZLanguageTraditionalChinese])
                                   && [googleTo isEqualToString:EZLanguageEnglish]) {
                            // 中文查词
                            NSMutableArray *simpleWords = [NSMutableArray array];
                            [dictResult enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                if (![obj isKindOfClass:NSArray.class]) {
                                    return;
                                }
                                NSString *part = [obj firstObject];
                                NSArray<NSArray *> *partWords = obj[2];
                                [partWords enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                    EZTranslateSimpleWord *word = [EZTranslateSimpleWord new];
                                    word.word = obj[0];
                                    word.means = [obj[1] mm_where:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                        return [obj isKindOfClass:NSString.class];
                                    }];
                                    word.part = part;
                                    [simpleWords addObject:word];
                                }];
                            }];
                            
                            if (simpleWords.count) {
                                wordResult.simpleWords = simpleWords.copy;
                            }
                        }
                        
                        if (wordResult.parts || wordResult.simpleWords) {
                            result.wordResult = wordResult;
                        }
                    }
                    
                    // 普通释义
                    NSArray<NSArray *> *normalArray = responseArray[0];
                    if (normalArray && [normalArray isKindOfClass:NSArray.class]) {
                        NSArray *normalResults = [normalArray mm_map:^id _Nullable(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            if ([obj isKindOfClass:[NSArray class]]) {
                                if (obj.count && [obj.firstObject isKindOfClass:[NSString class]]) {
                                    return obj.firstObject;
                                }
                            }
                            return nil;
                        }];
                        if (normalResults.count) {
                            result.normalResults = normalResults.copy;
                            
                            NSString *mergeString = [NSString mm_stringByCombineComponents:normalResults separatedString:@"\n"];
                            NSString *signTo = [[self.signFunction callWithArguments:@[ mergeString ]] toString];
                            result.toSpeakURL = [self getAudioURLWithText:mergeString language:[self languageCodeForLanguage:googleTo] sign:signTo];
                        }
                    }
                    
                    if (result.wordResult || result.normalResults) {
                        completion(result, nil);
                        return;
                    }
                    
                } @catch (NSException *exception) {
                    MMLogInfo(@"谷歌翻译接口数据解析异常 %@", exception);
                    message = @"谷歌翻译接口数据解析异常";
                }
            }
            [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
            completion(self.result, EZTranslateError(EZTranslateErrorTypeAPI, message ?: @"翻译失败", reqDict));
        }];
    };
    
    if ([from isEqualToString:EZLanguageAuto]) {
        // 需要先识别语言，用于指定目标语言
        [self detect:text
          completion:^(EZLanguage detectedLanguage, NSError *_Nullable error) {
            if (error) {
                completion(self.result, error);
                return;
            }
            translateBlock(text, detectedLanguage, to);
        }];
    } else {
        translateBlock(text, from, to);
    }
}

- (void)sendTranslateTKKText:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(id _Nullable responseObject, NSString *_Nullable signText, NSMutableDictionary *reqDict, NSError *_Nullable error))completion {
    NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
    
    NSString *url = [kGoogleRootPage(self.isCN) stringByAppendingPathComponent:@"/translate_a/single"];
    url = [url stringByAppendingString:@"?dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t"];
    NSDictionary *params = @{
        @"client" : @"webapp",
        @"sl" : [self languageCodeForLanguage:from], //
        @"tl" : [self languageCodeForLanguage:to],
        @"hl" : @"zh-CN",
        @"otf" : @"2",
        @"ssel" : @"3",
        @"tsel" : @"0",
        @"kc" : @"6",
        @"tk" : sign,
        @"q" : text,
    };
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params, EZTranslateErrorRequestParamKey, nil];
    
    [self.jsonSession GET:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if (responseObject) {
            completion(responseObject, sign, reqDict, nil);
        } else {
            completion(nil, nil, nil, EZTranslateError(EZTranslateErrorTypeAPI, @"翻译失败", reqDict));
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, nil, nil, EZTranslateError(EZTranslateErrorTypeNetwork, @"翻译失败", reqDict));
    }];
}

- (void)detect:(NSString *)text completion:(nonnull void (^)(EZLanguage, NSError *_Nullable))completion {
    //    [self detectSingleText:text completion:completion];
    [self detectTKKText:text completion:completion];
}

- (void)detectSingleText:(NSString *)text
              completion:(nonnull void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto, EZTranslateError(EZTranslateErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }
    
    // 截取一部分识别语言就行
    NSString *queryString = text;
    if (queryString.length >= 73) {
        queryString = [queryString substringToIndex:73];
    }
    
    [self sendTranslateSingleText:queryString
                             from:EZLanguageAuto
                               to:EZLanguageAuto
                       completion:^(id _Nullable responseObject,
                                    NSString *_Nullable signText,
                                    NSMutableDictionary *reqDict,
                                    NSError *_Nullable error) {
        if (error) {
            completion(EZLanguageAuto, error);
            return;
        }
        
        NSString *message = nil;
        @try {
            if ([responseObject
                 isKindOfClass:NSDictionary.class]) {
                NSDictionary *responseDict = responseObject;
                NSString *googleFromString = responseDict[@"src"];
                if ([googleFromString
                     isKindOfClass:NSString.class]) {
                    EZLanguage googleFrom = [self languageEnumFromCode:googleFromString];
                    if (googleFrom != EZLanguageAuto) {
                        completion(googleFrom, nil);
                        return;
                    }
                }
            }
        } @catch (NSException *exception) {
            MMLogInfo(@"谷歌翻译接口语言解析失败 %@",
                      exception);
        }
        [reqDict setObject:responseObject
                    forKey:EZTranslateErrorRequestResponseKey];
        completion(EZLanguageAuto,
                   EZTranslateError(EZTranslateErrorTypeAPI,
                                    message ?: @"识别语言失败",
                                    reqDict));
    }];
}

- (void)detectTKKText:(NSString *)text completion:(nonnull void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto, EZTranslateError(EZTranslateErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }
    
    // 截取一部分识别语言就行
    NSString *queryString = text;
    if (queryString.length >= 73) {
        queryString = [queryString substringToIndex:73];
    }
    
    [self sendTranslateTKKText:queryString from:EZLanguageAuto to:EZLanguageAuto completion:^(id _Nullable responseObject, NSString *_Nullable signText, NSMutableDictionary *reqDict, NSError *_Nullable error) {
        if (error) {
            completion(EZLanguageAuto, error);
            return;
        }
        
        NSString *message = nil;
        @try {
            if ([responseObject isKindOfClass:NSArray.class]) {
                NSArray *responseArray = responseObject;
                if (responseArray.count >= 3) {
                    NSString *googleFromString = responseArray[2];
                    EZLanguage googleFrom = [self languageEnumFromCode:googleFromString];
                    if (googleFrom != EZLanguageAuto) {
                        completion(googleFrom, nil);
                        return;
                    }
                }
            }
        } @catch (NSException *exception) {
            MMLogInfo(@"谷歌翻译接口语言解析失败 %@", exception);
        }
        [reqDict setObject:responseObject forKey:EZTranslateErrorRequestResponseKey];
        completion(EZLanguageAuto, EZTranslateError(EZTranslateErrorTypeAPI, message ?: @"识别语言失败", reqDict));
    }];
}

- (void)playTextAudio:(NSString *)text
         from:(EZLanguage)from
   completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }
    
    if ([from isEqualToString:EZLanguageAuto]) {
        // 判断语言
        mm_weakify(self)
        [self detect:text
          completion:^(EZLanguage lang, NSError *_Nullable error) {
            mm_strongify(self) if (error) {
                completion(nil, error);
                return;
            }
            
            NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
            NSString *url = [self
                             getAudioURLWithText:text
                             language:[self languageCodeForLanguage:lang]
                             sign:sign];
            completion(url, nil);
        }];
    } else {
        [self updateTKKWithCompletion:^(NSError *_Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            
            NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
            NSString *url = [self getAudioURLWithText:text
                                             language:[self languageCodeForLanguage:from]
                                                 sign:sign];
            completion(url, nil);
        }];
    }
}

- (NSString *)getAudioURLWithText:(NSString *)text
                         language:(NSString *)language
                             sign:(NSString *)sign {
    return [NSString
            stringWithFormat:@"%@/"
            @"translate_tts?ie=UTF-8&q=%@&tl=%@&total=1&idx=0&"
            @"textlen=%zd&tk=%@&client=webapp&prev=input",
            kGoogleRootPage(self.isCN), text.mm_urlencode, language,
            text.length, sign];
}

- (void)ocr:(NSImage *)image
       from:(EZLanguage)from
         to:(EZLanguage)to
 completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, EZTranslateError(EZTranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    
    // 暂未找到谷歌OCR接口，暂时用有道OCR代替
    // TODO: 考虑一下有没有语言问题
    [self.youdao ocr:image from:from to:to completion:completion];
}

- (void)ocrAndTranslate:(NSImage *)image
                   from:(EZLanguage)from
                     to:(EZLanguage)to
             ocrSuccess:(void (^)(EZOCRResult *_Nonnull, BOOL))ocrSuccess
             completion:(void (^)(EZOCRResult *_Nullable,
                                  EZQueryResult *_Nullable,
                                  NSError *_Nullable))completion {
    if (!image) {
        completion(nil, nil,
                   EZTranslateError(EZTranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    
    mm_weakify(self);
    [self ocr:image
         from:from
           to:to
   completion:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        mm_strongify(self);
        if (ocrResult) {
            ocrSuccess(ocrResult, YES);
            [self translate:ocrResult.mergedText
                       from:from
                         to:to
                 completion:^(EZQueryResult *_Nullable result,
                              NSError *_Nullable error) {
                completion(ocrResult, result, error);
            }];
        } else {
            completion(nil, nil, error);
        }
    }];
}

@end
