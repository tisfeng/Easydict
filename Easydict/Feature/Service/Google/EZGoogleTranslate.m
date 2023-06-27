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
#import "EZTextWordUtils.h"
#import "NSArray+EZChineseText.h"
#import "EZConfiguration.h"

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
        NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"google-translate-sign" ofType:@"js"];
        NSString *jsString = [NSString stringWithContentsOfFile:jsPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
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
        
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X "
         @"10_15_0) AppleWebKit/537.36 (KHTML, like "
         @"Gecko) Chrome/77.0.3865.120 Safari/537.36"
                 forHTTPHeaderField:@"User-Agent"];
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
        _youdao = [[EZYoudaoTranslate alloc] init];
    }
    return _youdao;
}

#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeGoogle;
}

- (EZQueryTextType)queryTextType {
    return EZQueryTextTypeDictionary | EZQueryTextTypeSentence | EZQueryTextTypeTranslation;
}

- (EZQueryTextType)intelligentQueryTextType {
    EZQueryTextType type = [EZConfiguration.shared intelligentQueryTextTypeForServiceType:self.serviceType];
    return type;
}

- (NSString *)name {
    return NSLocalizedString(@"google_translate", nil);
}

- (NSString *)link {
    return kGoogleTranslateURL;
}

// https://translate.google.com/?sl=auto&tl=zh-CN&text=good&op=translate
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *from = [self languageCodeForLanguage:queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:queryModel.queryTargetLanguage];
    NSString *maxText = [self maxTextLength:queryModel.inputText fromLanguage:queryModel.queryFromLanguage];
    NSString *text = [maxText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
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
                                        EZLanguageBurmese, @"my",
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
       completion:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:NO from:from to:to completion:completion]) {
        return;
    }
    
    text = [self maxTextLength:text fromLanguage:from];
    
    BOOL queryDictionary = [EZTextWordUtils shouldQueryDictionary:text language:from];
    if (queryDictionary) {
        // This API can get word info, like pronunciation.
        [self webApptranslate:text from:from to:to completion:completion];
    } else {
        [self gtxTranslate:text from:from to:to completion:completion];
    }
}

- (void)detectText:(NSString *)text completion:(nonnull void (^)(EZLanguage, NSError *_Nullable))completion {
    [self webAppDetectText:text completion:completion];
}

- (void)textToAudio:(NSString *)text
       fromLanguage:(EZLanguage)from
         completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(nil, EZTranslateError(EZErrorTypeParam, @"获取音频的文本为空", nil));
        return;
    }
    
    // TODO: need to optimize, Ref: https://github.com/florabtw/google-translate-tts/blob/master/src/synthesize.js
    
    if ([from isEqualToString:EZLanguageAuto]) {
        // 判断语言
        mm_weakify(self);
        [self detectText:text completion:^(EZLanguage lang, NSError *_Nullable error) {
            mm_strongify(self);
            if (error) {
                completion(nil, error);
                return;
            }
            
            NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
            NSString *url = [self getAudioURLWithText:text
                                             language:[self getTTSLanguageCode:lang]
                                                 sign:sign];
            completion(url, nil);
        }];
    } else {
        [self updateWebAppTKKWithCompletion:^(NSError *_Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            
            NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
            NSString *url = [self getAudioURLWithText:text
                                             language:[self getTTSLanguageCode:from]
                                                 sign:sign];
            completion(url, nil);
        }];
    }
}

- (NSString *)getAudioURLWithText:(NSString *)text
                         language:(NSString *)language
                             sign:(NSString *)sign {
    // TODO: text length must <= 200, maybe we can split it.
    text = [text trimToMaxLength:200];
    
    NSString *audioURL = [NSString stringWithFormat:@"%@/"
                          @"translate_tts?ie=UTF-8&q=%@&tl=%@&total=1&idx=0&"
                          @"textlen=%zd&tk=%@&client=webapp&prev=input",
                          kGoogleTranslateURL, text.mm_urlencode, language,
                          text.length, sign];
    return audioURL;
}

- (void)ocr:(NSImage *)image
       from:(EZLanguage)from
         to:(EZLanguage)to
 completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    if (!image) {
        completion(nil, EZTranslateError(EZErrorTypeParam, @"图片为空", nil));
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
        completion(nil, nil, EZTranslateError(EZErrorTypeParam, @"图片为空", nil));
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


#pragma mark - WebApp, including word info.

/// This API can get word info, like pronunciation, but transaltion may be inaccurate, compare to web transaltion.
- (void)webApptranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!text.length) {
        completion(self.result, EZTranslateError(EZErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    EZQueryResult *result = self.result;
    
    [self sendWebAppTranslate:text from:from to:to completion:^(id _Nullable responseObject, NSString *_Nullable signText, NSMutableDictionary *reqDict, NSError *_Nullable error) {
        if (error) {
            completion(result, error);
            return;
        }
        
        NSString *message = nil;
        if (responseObject && [responseObject isKindOfClass:NSArray.class]) {
            @try {
                NSArray *responseArray = responseObject;
                
                NSString *googleFromString = responseArray[2];
                EZLanguage googleFrom = [self languageEnumFromCode:googleFromString];
                EZLanguage googleTo = to;
                
                result.raw = responseObject;
                result.queryText = text;
                result.from = googleFrom;
                result.to = googleTo;
                result.fromSpeakURL = [self getAudioURLWithText:text language:googleFromString sign:signText];
                
                EZTranslateWordResult *wordResult;
                
                // 英文查词 中文查词
                NSArray *phoneticArray = responseArray[0];
                if (phoneticArray.count > 1) {
                    NSArray *phonetics = phoneticArray[1];
                    if (phonetics.count > 3) {
                        NSString *phoneticText = phonetics[3];
                        
                        wordResult = [[EZTranslateWordResult alloc] init];
                        
                        EZWordPhonetic *phonetic = [[EZWordPhonetic alloc] init];
                        phonetic.name = NSLocalizedString(@"us_phonetic", nil);
                        if ([EZLanguageManager.shared isChineseLanguage:from]) {
                            phonetic.name = NSLocalizedString(@"chinese_phonetic", nil);
                        }
                        
                        phonetic.value = phoneticText;
                        phonetic.speakURL = result.fromSpeakURL;
                        phonetic.language = result.queryModel.queryFromLanguage;
                        phonetic.word = text;
                        wordResult.phonetics = @[ phonetic ];
                    }
                }
                
                NSArray<NSArray *> *dictResult = responseArray[1];
                if (dictResult && [dictResult isKindOfClass:NSArray.class]) {
                    if (!wordResult) {
                        wordResult = [[EZTranslateWordResult alloc] init];
                    }
                    
                    if ([googleFrom isEqualToString:EZLanguageEnglish] &&
                        ([googleTo isEqualToString:EZLanguageSimplifiedChinese] || [googleTo isEqualToString:EZLanguageTraditionalChinese])) {
                        // 英文查词
                        NSMutableArray *parts = [NSMutableArray array];
                        [dictResult enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            if (![obj isKindOfClass:NSArray.class]) {
                                return;
                            }
                            EZTranslatePart *part = [[EZTranslatePart alloc] init];
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
                    } else if (([googleFrom isEqualToString:EZLanguageSimplifiedChinese] || [googleFrom isEqualToString:EZLanguageTraditionalChinese]) && [googleTo isEqualToString:EZLanguageEnglish]) {
                        // 中文查词
                        NSMutableArray *simpleWords = [NSMutableArray array];
                        [dictResult enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                            if (![obj isKindOfClass:NSArray.class]) {
                                return;
                            }
                            NSString *part = [obj firstObject];
                            NSArray<NSArray *> *partWords = obj[2];
                            [partWords enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                EZTranslateSimpleWord *word = [[EZTranslateSimpleWord alloc] init];
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
                }
                
                // Avoid displaying too long phonetic symbols.
                if (wordResult.parts || wordResult.simpleWords || text.length <= 4) {
                    result.wordResult = wordResult;
                }
                
                // 普通释义
                NSArray<NSArray *> *normalArray = responseArray[0];
                if (normalArray && [normalArray isKindOfClass:NSArray.class]) {
                    NSArray *normalResults = [normalArray mm_map:^id _Nullable(NSArray *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                        if ([obj isKindOfClass:[NSArray class]]) {
                            if (obj.count && [obj.firstObject isKindOfClass:[NSString class]]) {
                                return [obj.firstObject trim];
                            }
                        }
                        return nil;
                    }];
                    if (normalResults.count) {
                        result.translatedResults = normalResults.copy;
                        
                        NSString *mergeString = [NSString mm_stringByCombineComponents:normalResults separatedString:@"\n"];
                        NSString *signTo = [[self.signFunction callWithArguments:@[ mergeString ]] toString];
                        result.toSpeakURL = [self getAudioURLWithText:mergeString language:[self languageCodeForLanguage:googleTo] sign:signTo];
                    }
                }
                
                if (result.wordResult || result.translatedResults) {
                    completion(result, nil);
                    return;
                }
                
            } @catch (NSException *exception) {
                MMLogInfo(@"谷歌翻译接口数据解析异常 %@", exception);
                message = @"谷歌翻译接口数据解析异常";
            }
        }
        
        [self gtxTranslate:text from:from to:to completion:completion];
    }];
}

- (void)sendWebAppTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(id _Nullable responseObject, NSString *_Nullable signText, NSMutableDictionary *reqDict, NSError *_Nullable error))completion {
    NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
    
    NSString *url = [kGoogleTranslateURL stringByAppendingPathComponent:@"/translate_a/single"];
    url = [url stringByAppendingString:@"?dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t"];
    
    NSString *souceLangCode = [self languageCodeForLanguage:from];
    NSString *targetLangCode = [self languageCodeForLanguage:to];
    //    NSString *preferredLanguage = [EZLanguageManager firstLanguage];
    //    NSString *preferredLangCode = [self languageCodeForLanguage:preferredLanguage];
    
    NSDictionary *params = @{
        @"client" : @"webapp",
        @"sl" : souceLangCode, //
        @"tl" : targetLangCode,
        @"hl" : @"en", // zh-CN, en
        @"otf" : @"2",
        @"ssel" : @"3",
        @"tsel" : @"0",
        @"kc" : @"6",
        @"tk" : sign,
        @"q" : text,
    };
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:url, EZTranslateErrorRequestURLKey, params, EZTranslateErrorRequestParamKey, nil];
    
    NSURLSessionTask *task = [self.jsonSession GET:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }
        
        if (responseObject) {
            completion(responseObject, sign, reqDict, nil);
        } else {
            completion(nil, nil, nil, EZTranslateError(EZErrorTypeAPI, nil, reqDict));
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, nil, nil, EZTranslateError(EZErrorTypeNetwork, nil, reqDict));
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}

- (void)sendGetWebAppTKKRequestWithCompletion:(void (^)(NSString *_Nullable TKK, NSError *_Nullable error))completion {
    NSString *url = kGoogleTranslateURL;
    NSMutableDictionary *reqDict = [NSMutableDictionary dictionaryWithObject:url forKey:EZTranslateErrorRequestURLKey];
    
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
            completion(nil, EZTranslateError(EZErrorTypeAPI, @"谷歌翻译获取 tkk 失败", reqDict));
        }
    }
                  failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, EZTranslateError(EZErrorTypeAPI, @"谷歌翻译获取 tkk 失败", reqDict));
    }];
}

- (void)updateWebAppTKKWithCompletion:(void (^)(NSError *_Nullable error))completion {
    long long now = floor(NSDate.date.timeIntervalSince1970 / 3600);
    NSString *TKK = [[self.window objectForKeyedSubscript:@"TKK"] toString];
    NSArray<NSString *> *TKKComponents = [TKK componentsSeparatedByString:@"."];
    if (TKKComponents.firstObject.longLongValue == now) {
        completion(nil);
        return;
    }
    
    mm_weakify(self)
    [self sendGetWebAppTKKRequestWithCompletion:^(NSString *_Nullable TKK, NSError *_Nullable error) {
        mm_strongify(self) if (TKK) {
            [self.window setObject:TKK forKeyedSubscript:@"TKK"];
            completion(nil);
        }
        else {
            completion(error);
        }
    }];
}


#pragma mark - GTX Transalte, the same as web translation.

/// GTX can only get translation and src language.

- (void)sendGTXTranslate:(NSString *)text
                    from:(EZLanguage)from
                      to:(EZLanguage)to
              completion:(void (^)(id _Nullable responseObject,
                                   NSString *_Nullable signText,
                                   NSMutableDictionary *reqDict,
                                   NSError *_Nullable error))completion {
    NSString *sign = [[self.signFunction callWithArguments:@[ text ]] toString];
    NSString *url = [kGoogleTranslateURL stringByAppendingPathComponent:@"/translate_a/single"];
    
    NSString *fromLanguage = [self languageCodeForLanguage:from];
    NSString *toLanguage = [self languageCodeForLanguage:to];
    
    /**
     TODO: This API translates the same content as the web version, but it makes its own line breaks. Later, we need to switch to the API that is exactly the same as the web page.
     */
    NSDictionary *params = @{
        @"q" : text,
        @"sl" : fromLanguage,
        @"tl" : toLanguage,
        @"dt" : @"t",
        @"dj" : @"1",
        @"ie" : @"UTF-8",
        @"client" : @"gtx",
    };
    
    NSMutableDictionary *reqDict = @{
        EZTranslateErrorRequestURLKey : url,
        EZTranslateErrorRequestParamKey : params,
    }.mutableCopy;
    
    NSURLSessionTask *task = [self.jsonSession GET:url
                                        parameters:params
                                          progress:nil
                                           success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }
        
        if (responseObject) {
            completion(responseObject, sign, reqDict, nil);
        } else {
            completion(nil, nil, nil, EZTranslateError(EZErrorTypeAPI, nil, reqDict));
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        [reqDict setObject:error forKey:EZTranslateErrorRequestErrorKey];
        completion(nil, nil, nil, EZTranslateError(EZErrorTypeNetwork, nil, reqDict));
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}

- (void)gtxTranslate:(NSString *)text
                from:(EZLanguage)from
                  to:(EZLanguage)to
          completion:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    EZQueryResult *result = self.result;
    
    if (!text.length) {
        completion(result, EZTranslateError(EZErrorTypeParam, @"翻译的文本为空", nil));
        return;
    }
    
    [self sendGTXTranslate:text
                      from:from
                        to:to
                completion:^(id _Nullable responseObject,
                             NSString *_Nullable signText,
                             NSMutableDictionary *reqDict,
                             NSError *_Nullable error) {
        if (error) {
            completion(result, error);
            return;
        }
        
        NSString *message = nil;
        if (responseObject && [responseObject isKindOfClass:NSDictionary.class]) {
            @try {
                NSDictionary *responseDict = responseObject;
                NSString *googleFromString = responseDict[@"src"];
                
                EZLanguage googleFrom = [self languageEnumFromCode:googleFromString];
                
                // Sometimes, scr is different from extended_srclangs, such as "開門 ": src = "zh-CN", extended_srclangs = "zh-TW"
                NSArray *extended_srclangs = responseDict[@"ld_result"][@"extended_srclangs"];
                if (extended_srclangs.count) {
                    NSString *language = extended_srclangs.firstObject;
                    if ([language isKindOfClass:[NSString class]]) {
                        EZLanguage ezlanguage = [self languageEnumFromCode:language];
                        if (![ezlanguage isEqualToString:EZLanguageAuto]) {
                            googleFrom = ezlanguage;
                            googleFromString = language;
                        }
                    }
                }
                
                EZLanguage googleTo = to;
                
                result.queryText = text;
                result.from = googleFrom;
                result.to = googleTo;
                result.fromSpeakURL = [self getAudioURLWithText:text language:googleFromString sign:signText];
                
                // 普通释义
                NSArray *sentences = responseDict[@"sentences"];
                if (sentences && [sentences isKindOfClass:NSArray.class]) {
                    NSMutableArray *translationArray = [NSMutableArray array];
                    
                    // !!!: This Google API has its own paragraph, \n\n , we need to join and convert to text array.
                    for (NSDictionary *sentenceDict in sentences) {
                        NSString *trans = sentenceDict[@"trans"];
                        if (trans && [trans isKindOfClass:NSString.class]) {
                            [translationArray addObject:trans];
                        }
                    }

                    NSString *transaltedText = [translationArray componentsJoinedByString:@""];
                    result.translatedResults = [transaltedText toParagraphs];
                    
                    NSString *signTo = [[self.signFunction callWithArguments:@[ transaltedText ]] toString];
                    result.toSpeakURL = [self getAudioURLWithText:transaltedText
                                                         language:[self languageCodeForLanguage:googleTo]
                                                             sign:signTo];
                }
                
                if (result.wordResult || result.translatedResults) {
                    completion(result, nil);
                    return;
                }
                
            } @catch (NSException *exception) {
                MMLogInfo(@"谷歌翻译接口数据解析异常 %@", exception);
                message = @"谷歌翻译接口数据解析异常";
            }
        }
        [reqDict setObject:responseObject ?: [NSNull null] forKey:EZTranslateErrorRequestResponseKey];
        completion(result, EZTranslateError(EZErrorTypeAPI, message ?: nil, reqDict));
    }];
}

- (void)gtxDetectText:(NSString *)text
           completion:(nonnull void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto, EZTranslateError(EZErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }
    
    // 截取一部分识别语言就行
    NSString *queryString = [text trimToMaxLength:73];
    
    [self sendGTXTranslate:queryString
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
        [reqDict setObject:responseObject forKey:EZTranslateErrorRequestResponseKey];
        completion(EZLanguageAuto,
                   EZTranslateError(EZErrorTypeAPI, message ?: @"识别语言失败", reqDict));
    }];
}

- (void)webAppDetectText:(NSString *)text completion:(nonnull void (^)(EZLanguage, NSError *_Nullable))completion {
    if (!text.length) {
        completion(EZLanguageAuto,
                   EZTranslateError(EZErrorTypeParam, @"识别语言的文本为空", nil));
        return;
    }
    
    // 截取一部分识别语言就行
    NSString *queryString = [text trimToMaxLength:73];
    
    [self sendWebAppTranslate:queryString from:EZLanguageAuto to:EZLanguageAuto completion:^(id _Nullable responseObject, NSString *_Nullable signText, NSMutableDictionary *reqDict, NSError *_Nullable error) {
        if (error) {
            completion(EZLanguageAuto, error);
            return;
        }
        
        NSString *message = nil;
        @try {
            if ([responseObject isKindOfClass:NSArray.class]) {
                NSArray *responseArray = responseObject;
                if (responseArray.count > 2) {
                    NSString *googleFromString = responseArray[2];
                    // !!!: Note: it may be auto if it's unsupported language.
                    EZLanguage googleFromLanguage = [self languageEnumFromCode:googleFromString];
                    
                    /**
                     Sometimes, scr is different from extended_srclangs, such as "開門 ": src = "zh-CN", extended_srclangs = "zh-TW"
                     
                     [
                     [
                     "zh-CN"
                     ],
                     null,
                     [
                     0.9609375
                     ],
                     [
                     "zh-TW"
                     ]
                     ]
                     */
                    if (responseArray.count > 8) {
                        NSArray *languageArray = responseArray[8];
                        if ([languageArray isKindOfClass:[NSArray class]]) {
                            NSArray *languages = languageArray.lastObject;
                            if ([languages isKindOfClass:[NSArray class]]) {
                                NSString *language = languages.firstObject;
                                if ([language isKindOfClass:[NSString class]]) {
                                    NSLog(@"Google detect language: %@", language);
                                    EZLanguage ezlanguage = [self languageEnumFromCode:language];
                                    if (![ezlanguage isEqualToString:EZLanguageAuto]) {
                                        googleFromLanguage = ezlanguage;
                                    }
                                }
                            }
                        }
                    }
                    
                    completion(googleFromLanguage, nil);
                    return;
                }
            }
        } @catch (NSException *exception) {
            MMLogInfo(@"谷歌翻译接口语言解析失败 %@", exception);
        }
        [reqDict setObject:responseObject forKey:EZTranslateErrorRequestResponseKey];
        completion(EZLanguageAuto, EZTranslateError(EZErrorTypeAPI, message ?: @"识别语言失败", reqDict));
    }];
}

#pragma mark -

/// Get max text length for Google Translate.
- (NSString *)maxTextLength:(NSString *)text fromLanguage:(EZLanguage)from {
    // Chinese max text length 1800
    // English max text length 5000
    if ([EZLanguageManager.shared isChineseLanguage:from] && text.length > 1800) {
        text = [text substringToIndex:1800];
    } else {
        text = [text trimToMaxLength:5000];
    }
    
    return text;
}

@end
