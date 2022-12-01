//
//  GoogleTranslate.m
//  Bob
//
//  Created by ripper on 2019/12/18.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "GoogleTranslate.h"
#import "YoudaoTranslate.h"
#import <JavaScriptCore/JavaScriptCore.h>

#define kGoogleRootPage(isCN) (isCN ? @"https://translate.google.cn" : @"https://translate.google.com")

@interface GoogleTranslate ()

@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic, strong) JSValue *signFunction;
@property (nonatomic, strong) JSValue *window;
@property (nonatomic, strong) AFHTTPSessionManager *htmlSession;
@property (nonatomic, strong) AFHTTPSessionManager *jsonSession;
@property (nonatomic, strong) YoudaoTranslate *youdao;

@end

@implementation GoogleTranslate

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

- (YoudaoTranslate *)youdao {
    if (!_youdao) {
        _youdao = [YoudaoTranslate new];
    }
    return _youdao;
}

#pragma mark -

- (void)sendGetTKKRequestWithCompletion:
(void (^)(NSString *_Nullable TKK, NSError *_Nullable error))completion {
    NSString *url = kGoogleRootPage(self.isCN);
    NSMutableDictionary *reqDict =
    [NSMutableDictionary dictionaryWithObject:url
                                       forKey:TranslateErrorRequestURLKey];
    
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
                        forKey:TranslateErrorRequestResponseKey];
            completion(nil, TranslateError(TranslateErrorTypeAPI, @"谷歌翻译获取 tkk 失败", reqDict));
        }
    }
                  failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:TranslateErrorRequestErrorKey];
        completion(nil, TranslateError(TranslateErrorTypeAPI, @"谷歌翻译获取 tkk 失败", reqDict));
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
                           from:(Language)from
                             to:(Language)to
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
        @"sl" : [self languageStringFromEnum:from],
        @"tl" : [self languageStringFromEnum:to],
        @"dt" : @"t",
        @"dj" : @"1",
        @"ie" : @"UTF-8",
        @"client" : @"gtx",
    };
    NSMutableDictionary *reqDict = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:url, TranslateErrorRequestURLKey, params,
                                    TranslateErrorRequestParamKey, nil];
    
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
                       TranslateError(TranslateErrorTypeAPI, @"翻译失败", reqDict));
        }
    }
                  failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:TranslateErrorRequestErrorKey];
        completion(
                   nil, nil, nil,
                   TranslateError(TranslateErrorTypeNetwork, @"翻译失败", reqDict));
    }];
}

#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeGoogle;
}

- (NSString *)identifier {
    return self.isCN ? @"google_cn" : @"Google";
}

- (NSString *)name {
    return self.isCN ? @"谷歌翻译(国内)" : @"谷歌翻译";
}

- (NSString *)link {
    return kGoogleRootPage(self.isCN);
}

//- (MMOrderedDictionary *)supportLanguagesDictionary {
//    return [[MMOrderedDictionary alloc]
//            initWithKeysAndObjects:
//                @(Language_auto), @"auto", @(Language_zh_Hans), @"zh-CN", // zh ?
//            @(Language_zh_Hant), @"zh-TW", @(Language_en), @"en", @(Language_af),
//            @"af", @(Language_sq), @"sq", @(Language_am), @"am", @(Language_ar),
//            @"ar", @(Language_hy), @"hy", @(Language_az), @"az", @(Language_eu),
//            @"eu", @(Language_be), @"be", @(Language_bn), @"bn", @(Language_bs),
//            @"bs", @(Language_bg), @"bg", @(Language_ca), @"ca", @(Language_ceb),
//            @"ceb", @(Language_ny), @"ny", @(Language_co), @"co", @(Language_hr),
//            @"hr", @(Language_cs), @"cs", @(Language_da), @"da", @(Language_nl),
//            @"nl", @(Language_eo), @"eo", @(Language_et), @"et", @(Language_tl),
//            @"tl", @(Language_fi), @"fi", @(Language_fr), @"fr", @(Language_fy),
//            @"fy", @(Language_gl), @"gl", @(Language_ka), @"ka", @(Language_de),
//            @"de", @(Language_el), @"el", @(Language_gu), @"gu", @(Language_ht),
//            @"ht", @(Language_ha), @"ha", @(Language_haw), @"haw", @(Language_he),
//            @"iw", // google 这个 code 码有点特别
//            @(Language_hi), @"hi", @(Language_hmn), @"hmn", @(Language_hu), @"hu",
//            @(Language_is), @"is", @(Language_ig), @"ig", @(Language_id), @"id",
//            @(Language_ga), @"ga", @(Language_it), @"it", @(Language_ja), @"ja",
//            @(Language_jw), @"jw", @(Language_kn), @"kn", @(Language_kk), @"kk",
//            @(Language_km), @"km", @(Language_ko), @"ko", @(Language_ku), @"ku",
//            @(Language_ky), @"ky", @(Language_lo), @"lo", @(Language_la), @"la",
//            @(Language_lv), @"lv", @(Language_lt), @"lt", @(Language_lb), @"lb",
//            @(Language_mk), @"mk", @(Language_mg), @"mg", @(Language_ms), @"ms",
//            @(Language_ml), @"ml", @(Language_mt), @"mt", @(Language_mi), @"mi",
//            @(Language_mr), @"mr", @(Language_mn), @"mn", @(Language_my), @"my",
//            @(Language_ne), @"ne", @(Language_no), @"no", @(Language_ps), @"ps",
//            @(Language_fa), @"fa", @(Language_pl), @"pl", @(Language_pt), @"pt",
//            @(Language_pa), @"pa", @(Language_ro), @"ro", @(Language_ru), @"ru",
//            @(Language_sm), @"sm", @(Language_gd), @"gd", @(Language_sr), @"sr",
//            @(Language_st), @"st", @(Language_sn), @"sn", @(Language_sd), @"sd",
//            @(Language_si), @"si", @(Language_sk), @"sk", @(Language_sl), @"sl",
//            @(Language_so), @"so", @(Language_es), @"es", @(Language_su), @"su",
//            @(Language_sw), @"sw", @(Language_sv), @"sv", @(Language_tg), @"tg",
//            @(Language_ta), @"ta", @(Language_te), @"te", @(Language_th), @"th",
//            @(Language_tr), @"tr", @(Language_uk), @"uk", @(Language_ur), @"ur",
//            @(Language_uz), @"uz", @(Language_vi), @"vi", @(Language_cy), @"cy",
//            @(Language_xh), @"xh", @(Language_yi), @"yi", @(Language_yo), @"yo",
//            @(Language_zu), @"zu", nil];
//}

// Currently supports 48 languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, Spanish, Portuguese, Italian, German, Russian, Arabic, Swedish, Romanian, Thai, Slovak, Dutch, Hungarian, Greek, Danish, Finnish, Polish, Czech, Turkish, Lithuanian, Latvian, Ukrainian, Bulgarian, Indonesian, Malay, Slovenian, Estonian, Vietnamese, Persian, Hindi, Telugu, Tamil, Urdu, Filipino, Khmer, Lao, Bengali, Burmese, Norwegian, Serbian, Croatian, Mongolian, Hebrew.

// get supportLanguagesDictionary, key is EZLanguage, value is NLLanguage, such as EZLanguageAuto, NLLanguageUndetermined
- (MMOrderedDictionary *)supportLanguagesDictionary {
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
             from:(Language)from
               to:(Language)to
       completion:(nonnull void (^)(TranslateResult *_Nullable,
                                    NSError *_Nullable))completion {
    //    [self translateSingleText:text from:from to:to completion:completion];
    [self translateTKKText:text from:from to:to completion:completion];
}


- (void)translateSingleText:(NSString *)text
                       from:(Language)from
                         to:(Language)to
                 completion:(nonnull void (^)(TranslateResult *_Nullable,
                                              NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil,
                   TranslateError(TranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    void (^translateBlock)(NSString *, Language, Language) =
    ^(
      NSString *text, Language langFrom, Language langTo) {
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
                      
                      NSString *textEncode = text.mm_urlencode;
                      NSString *googleFromString =
                      responseDict[@"src"];
                      Language googleFrom = [self
                                             languageEnumFromString:googleFromString];
                      Language googleTo = langTo;
                      
                      TranslateResult *result = [TranslateResult new];
                      self.result = result;
                      
                      result.text = text;
                      result.from = googleFrom;
                      result.to = googleTo;
                      result.link = [NSString
                                     stringWithFormat:
                                         @"%@/"
                                     @"#view=home&op=translate&sl=%@&tl=%@&"
                                     @"text=%@",
                                     kGoogleRootPage(self.isCN),
                                     googleFromString,
                                     [self languageStringFromEnum:googleTo],
                                     textEncode];
                      result.fromSpeakURL =
                      [self getAudioURLWithText:text
                                       language:googleFromString
                                           sign:signText];
                      
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
                                                        languageStringFromEnum:
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
               forKey:TranslateErrorRequestResponseKey];
              completion(nil,
                         TranslateError(TranslateErrorTypeAPI,
                                        message ?: @"翻译失败",
                                        reqDict));
          }];
      };
    
    if (from == Language_auto) {
        // 需要先识别语言，用于指定目标语言
        [self detect:text
          completion:^(Language lang, NSError *_Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            
            Language langTo = [self getTargetLanguageWithSourceLanguage:lang];
            translateBlock(text, lang, langTo);
        }];
    } else {
        to = [self getTargetLanguageWithSourceLanguage:from];
        translateBlock(text, from, to);
    }
}

- (void)translateTKKText:(NSString *)text from:(Language)from to:(Language)to completion:(nonnull void (^)(TranslateResult *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, TranslateError(TranslateErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    void (^translateBlock)(NSString *, Language, Language) = ^(NSString *text, Language langFrom, Language langTo) {
        [self sendTranslateTKKText:text from:langFrom to:langTo completion:^(id _Nullable responseObject, NSString *_Nullable signText, NSMutableDictionary *reqDict, NSError *_Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            
            NSString *message = nil;
            if (responseObject && [responseObject isKindOfClass:NSArray.class]) {
                @try {
                    NSArray *responseArray = responseObject;
                    
                    NSString *textEncode = text.mm_urlencode;
                    NSString *googleFromString = responseArray[2];
                    Language googleFrom = [self languageEnumFromString:googleFromString];
                    Language googleTo = langTo;
                    
                    TranslateResult *result = [TranslateResult new];
                    self.result = result;
                    
                    result.text = text;
                    result.from = googleFrom;
                    result.to = googleTo;
                    result.link = [NSString stringWithFormat:@"%@/#view=home&op=translate&sl=%@&tl=%@&text=%@",
                                   kGoogleRootPage(self.isCN),
                                   googleFromString,
                                   [self languageStringFromEnum:googleTo],
                                   textEncode];
                    result.fromSpeakURL = [self getAudioURLWithText:text language:googleFromString sign:signText];
                    
                    // 英文查词 中文查词
                    NSArray<NSArray *> *dictResult = responseArray[1];
                    if (dictResult && [dictResult isKindOfClass:NSArray.class]) {
                        TranslateWordResult *wordResult = [TranslateWordResult new];
                        
                        NSString *phoneticText = responseArray[0][1][3];
                        if (phoneticText) {
                            TranslatePhonetic *phonetic = [TranslatePhonetic new];
                            phonetic.name = @"美";
                            phonetic.value = phoneticText;
                            phonetic.speakURL = result.fromSpeakURL;
                            
                            wordResult.phonetics = @[ phonetic ];
                        }
                        
                        if (googleFrom == Language_en &&
                            (googleTo == Language_zh_Hans || googleTo == Language_zh_Hant)) {
                            // 英文查词
                            NSMutableArray *parts = [NSMutableArray array];
                            [dictResult enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                if (![obj isKindOfClass:NSArray.class]) {
                                    return;
                                }
                                TranslatePart *part = [TranslatePart new];
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
                        } else if ((googleFrom == Language_zh_Hans || googleFrom == Language_zh_Hant) &&
                                   googleTo == Language_en) {
                            // 中文查词
                            NSMutableArray *simpleWords = [NSMutableArray array];
                            [dictResult enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                if (![obj isKindOfClass:NSArray.class]) {
                                    return;
                                }
                                NSString *part = [obj firstObject];
                                NSArray<NSArray *> *partWords = obj[2];
                                [partWords enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                    TranslateSimpleWord *word = [TranslateSimpleWord new];
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
                            result.toSpeakURL = [self getAudioURLWithText:mergeString language:[self languageStringFromEnum:googleTo] sign:signTo];
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
            [reqDict setObject:responseObject ?: [NSNull null] forKey:TranslateErrorRequestResponseKey];
            completion(nil, TranslateError(TranslateErrorTypeAPI, message ?: @"翻译失败", reqDict));
        }];
    };
    
    if (from == Language_auto) {
        // 需要先识别语言，用于指定目标语言
        [self detect:text
          completion:^(Language lang, NSError *_Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            
            Language langTo = [self getTargetLanguageWithSourceLanguage:lang];
            translateBlock(text, lang, langTo);
        }];
    } else {
        to = [self getTargetLanguageWithSourceLanguage:from];
        translateBlock(text, from, to);
    }
    
    //    if (to == Language_auto) {
    //        // 需要先识别语言，用于指定目标语言
    //        [self detect:text completion:^(Language lang, NSError * _Nullable error) {
    //            if (error) {
    //                completion(nil, error);
    //                return;
    //            }
    //
    //            Language langTo = Language_auto;
    //            if (lang == Language_zh_Hans || lang == Language_zh_Hant) {
    //                langTo = Language_en;
    //            }else {
    //                langTo = Language_zh_Hans;
    //            }
    //            translateBlock(text, lang, langTo);
    //        }];
    //    }else {
    //        translateBlock(text, from, to);
    //    }
}

- (void)sendTranslateTKKText:(NSString *)text from:(Language)from to:(Language)to completion:(void (^)(id _Nullable responseObject, NSString *_Nullable signText, NSMutableDictionary *reqDict, NSError *_Nullable error))completion {
    NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
    
    NSString *url = [kGoogleRootPage(self.isCN) stringByAppendingPathComponent:@"/translate_a/single"];
    url = [url stringByAppendingString:@"?dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t"];
    NSDictionary *params = @{
        @"client" : @"webapp",
        @"sl" : [self languageStringFromEnum:from],
        @"tl" : [self languageStringFromEnum:to],
        @"hl" : @"zh-CN",
        @"otf" : @"2",
        @"ssel" : @"3",
        @"tsel" : @"0",
        @"kc" : @"6",
        @"tk" : sign,
        @"q" : text,
    };
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, TranslateErrorRequestURLKey, params, TranslateErrorRequestParamKey, nil];
    
    [self.jsonSession GET:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if (responseObject) {
            completion(responseObject, sign, reqDict, nil);
        } else {
            completion(nil, nil, nil, TranslateError(TranslateErrorTypeAPI, @"翻译失败", reqDict));
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:TranslateErrorRequestErrorKey];
        completion(nil, nil, nil, TranslateError(TranslateErrorTypeNetwork, @"翻译失败", reqDict));
    }];
}


// Get target language with source language
- (Language)getTargetLanguageWithSourceLanguage:(Language)sourceLanguage {
    Language targetLanguage = Language_auto;
    if (sourceLanguage == Language_zh_Hans || sourceLanguage == Language_zh_Hant) {
        targetLanguage = Language_en;
    } else {
        targetLanguage = Language_zh_Hans;
    }
    return targetLanguage;
}

- (void)detect:(NSString *)text completion:(nonnull void (^)(Language, NSError *_Nullable))completion {
    //    [self detectSingleText:text completion:completion];
    [self detectTKKText:text completion:completion];
}

- (void)detectSingleText:(NSString *)text
              completion:(nonnull void (^)(Language, NSError *_Nullable))completion {
    if (!text.length) {
        completion(Language_auto, TranslateError(TranslateErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }
    
    // 截取一部分识别语言就行
    NSString *queryString = text;
    if (queryString.length >= 73) {
        queryString = [queryString substringToIndex:73];
    }
    
    [self sendTranslateSingleText:queryString
                             from:Language_auto
                               to:Language_auto
                       completion:^(id _Nullable responseObject,
                                    NSString *_Nullable signText,
                                    NSMutableDictionary *reqDict,
                                    NSError *_Nullable error) {
        if (error) {
            completion(Language_auto, error);
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
                    Language googleFrom = [self languageEnumFromString:googleFromString];
                    if (googleFrom != Language_auto) {
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
                    forKey:TranslateErrorRequestResponseKey];
        completion(Language_auto,
                   TranslateError(TranslateErrorTypeAPI,
                                  message ?: @"识别语言失败",
                                  reqDict));
    }];
}

- (void)detectTKKText:(NSString *)text completion:(nonnull void (^)(Language, NSError *_Nullable))completion {
    if (!text.length) {
        completion(Language_auto, TranslateError(TranslateErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }
    
    // 截取一部分识别语言就行
    NSString *queryString = text;
    if (queryString.length >= 73) {
        queryString = [queryString substringToIndex:73];
    }
    
    [self sendTranslateTKKText:queryString from:Language_auto to:Language_auto completion:^(id _Nullable responseObject, NSString *_Nullable signText, NSMutableDictionary *reqDict, NSError *_Nullable error) {
        if (error) {
            completion(Language_auto, error);
            return;
        }
        
        NSString *message = nil;
        @try {
            if ([responseObject isKindOfClass:NSArray.class]) {
                NSArray *responseArray = responseObject;
                if (responseArray.count >= 3) {
                    NSString *googleFromString = responseArray[2];
                    Language googleFrom = [self languageEnumFromString:googleFromString];
                    if (googleFrom != Language_auto) {
                        completion(googleFrom, nil);
                        return;
                    }
                }
            }
        } @catch (NSException *exception) {
            MMLogInfo(@"谷歌翻译接口语言解析失败 %@", exception);
        }
        [reqDict setObject:responseObject forKey:TranslateErrorRequestResponseKey];
        completion(Language_auto, TranslateError(TranslateErrorTypeAPI, message ?: @"识别语言失败", reqDict));
    }];
}

- (void)audio:(NSString *)text
         from:(Language)from
   completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, TranslateError(TranslateErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }
    
    if (from == Language_auto) {
        // 判断语言
        mm_weakify(self)
        [self detect:text
          completion:^(Language lang, NSError *_Nullable error) {
            mm_strongify(self) if (error) {
                completion(nil, error);
                return;
            }
            
            NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
            NSString *url = [self
                             getAudioURLWithText:text
                             language:[self languageStringFromEnum:lang]
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
                                             language:[self languageStringFromEnum:from]
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
       from:(Language)from
         to:(Language)to
 completion:(void (^)(OCRResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, TranslateError(TranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    
    // 暂未找到谷歌OCR接口，暂时用有道OCR代替
    // TODO: 考虑一下有没有语言问题
    [self.youdao ocr:image from:from to:to completion:completion];
}

- (void)ocrAndTranslate:(NSImage *)image
                   from:(Language)from
                     to:(Language)to
             ocrSuccess:(void (^)(OCRResult *_Nonnull, BOOL))ocrSuccess
             completion:(void (^)(OCRResult *_Nullable,
                                  TranslateResult *_Nullable,
                                  NSError *_Nullable))completion {
    if (!image) {
        completion(nil, nil,
                   TranslateError(TranslateErrorTypeParam, @"图片为空", nil));
        return;
    }
    
    mm_weakify(self);
    [self ocr:image
         from:from
           to:to
   completion:^(OCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        mm_strongify(self);
        if (ocrResult) {
            ocrSuccess(ocrResult, YES);
            [self translate:ocrResult.mergedText
                       from:from
                         to:to
                 completion:^(TranslateResult *_Nullable result,
                              NSError *_Nullable error) {
                completion(ocrResult, result, error);
            }];
        } else {
            completion(nil, nil, error);
        }
    }];
}

@end
