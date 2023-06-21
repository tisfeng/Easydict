//
//  EZDeepLTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZDeepLTranslate.h"
#import "EZWebViewTranslator.h"
#import "EZTranslateError.h"
#import "EZQueryResult+EZDeepLTranslateResponse.h"
#import "NSArray+EZChineseText.h"

static NSString *kDeepLTranslateURL = @"https://www.deepl.com/translator";

@interface EZDeepLTranslate ()

@property (nonatomic, strong) EZWebViewTranslator *webViewTranslator;

@property (nonatomic, copy) NSString *authKey;

@property (nonatomic, assign) EZDeepLTranslationAPI apiType;

@end

@implementation EZDeepLTranslate

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (EZWebViewTranslator *)webViewTranslator {
    if (!_webViewTranslator) {
        NSString *selector = @"#target-dummydiv";
        _webViewTranslator = [[EZWebViewTranslator alloc] init];
        _webViewTranslator.querySelector = selector;
        _webViewTranslator.queryModel = self.queryModel;
    }
    return _webViewTranslator;
}

- (NSString *)authKey {
    NSString *authKey = [[NSUserDefaults standardUserDefaults] stringForKey:EZDeepLAuthKey] ?: @"";
    return authKey;
}

- (EZDeepLTranslationAPI)apiType {
    EZDeepLTranslationAPI type = [[NSUserDefaults mm_readString:EZDeepLTranslationAPIKey defaultValue:@"0"] integerValue];
    return type;
}

#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeDeepL;
}

- (NSString *)name {
    return NSLocalizedString(@"deepL_translate", nil);
}

- (NSString *)link {
    return kDeepLTranslateURL;
}

// https://www.deepl.com/translator#en/zh/good
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *from = [self languageCodeForLanguage:queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:queryModel.queryTargetLanguage];
    NSString *text = [queryModel.inputText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    /**
     !!!: need to convert '/' to '%5C%2F'
     
     e.g. https://www.deepl.com/translator#en/zh/computer%5C%2FFserver
     
     FIX: https://github.com/tisfeng/Easydict/issues/60
     */
    NSString *encodedText = [text stringByReplacingOccurrencesOfString:@"/" withString:@"%5C%2F"];

    if (!from || !to) {
        return nil;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@#%@/%@/%@", kDeepLTranslateURL, from, to, encodedText];

    return url;
}

// Supported languages: https://www.deepl.com/zh/docs-api/translate-text/
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                                                        EZLanguageAuto, @"auto",
                                                                        EZLanguageSimplifiedChinese, @"zh",
                                                                        EZLanguageTraditionalChinese, @"zh",
                                                                        EZLanguageEnglish, @"en",
                                                                        EZLanguageJapanese, @"ja",
                                                                        EZLanguageKorean, @"ko",
                                                                        EZLanguageFrench, @"fr",
                                                                        EZLanguageSpanish, @"es",
                                                                        EZLanguagePortuguese, @"pt",
                                                                        EZLanguageItalian, @"it",
                                                                        EZLanguageGerman, @"de",
                                                                        EZLanguageRussian, @"ru",
                                                                        EZLanguageSwedish, @"sv",
                                                                        EZLanguageRomanian, @"ro",
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
                                                                        EZLanguageSlovenian, @"sl",
                                                                        EZLanguageEstonian, @"et",
                                                                        EZLanguageNorwegian, @"nb",
                                                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:YES from:from to:to completion:completion]) {
        return;
    }
    
    mm_weakify(self);
    [self setDidFinishBlock:^(EZQueryResult *result, NSError *error) {
        mm_strongify(self);
        NSArray *texts = result.translatedResults;
        if ([self.queryModel.queryTargetLanguage isEqualToString:EZLanguageTraditionalChinese]) {
            texts = [texts toTraditionalChineseTexts];
        }
        result.translatedResults = texts;
    }];
    
    void (^callback)(EZQueryResult *result, NSError *error) = ^(EZQueryResult *result, NSError *error) {
        self.didFinishBlock(result, error);
        completion(result, error);
    };
        
    if (self.apiType == EZDeepLTranslationAPIWebFirst) {
        [self deepLWebTranslate:text from:from to:to completion:callback];
    } else {
        [self deepLTranslate:text from:from to:to completion:callback];
    }
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"deepL not support ocr");
}

#pragma mark - WebView Translate

- (void)webViewTranslate:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *wordLink = [self wordLink:self.queryModel];
    
    mm_weakify(self);
    [self.queryModel setStopBlock:^{
        mm_strongify(self);
        [self.webViewTranslator resetWebView];
    } serviceType:self.serviceType];
    
    [self.webViewTranslator queryTranslateURL:wordLink completionHandler:^(NSArray<NSString *> *_Nonnull texts, NSError *_Nonnull error) {
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }

        self.result.translatedResults = texts;
        completion(self.result, error);
    }];

    //    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    //    NSString *monitorURL = @"https://www2.deepl.com/jsonrpc?method=LMT_handle_jobs";
    //    [self.webViewTranslator monitorBaseURLString:monitorURL
    //                                         loadURL:self.wordLink
    //                               completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
    //        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    //        NSLog(@"API deepL cost: %.1f ms", (endTime - startTime) * 1000); // cost ~2s
    //
    //        //        NSLog(@"deepL responseObject: %@", responseObject);
    //    }];
}

#pragma mark - DeepL Web Translate

/// DeepL web translate. Ref: https://github.com/akl7777777/bob-plugin-akl-deepl-free-translate/blob/9d194783b3eb8b3a82f21bcfbbaf29d6b28c2761/src/main.js
- (void)deepLWebTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *souceLangCode = [self languageCodeForLanguage:from];
    NSString *targetLangCode = [self languageCodeForLanguage:to];

    NSString *url = @"https://"
                    @"www2."
                    @"deepl.com"
                    @"/jsonrpc";
    
    NSInteger ID = [self getRandomNumber];
    NSInteger iCount = [self getICount:text];
    NSTimeInterval ts = [self getTimeStampWithIcount:iCount];
    NSDictionary *params = @{
        @"texts" : @[ @{@"text" : text, @"requestAlternatives" : @(3)} ],
        @"splitting" : @"newlines",
        @"lang" : @{@"source_lang_user_selected" : souceLangCode, @"target_lang" : targetLangCode},
        @"timestamp" : @(ts)
    };
    NSDictionary *postData = @{
        @"jsonrpc" : @"2.0",
        @"method" : @"LMT_handle_texts",
        @"id" : @(ID),
        @"params" : params
    };
    //    NSLog(@"postData: %@", postData);

    NSString *postStr = [postData mj_JSONString];
    if ((ID + 5) % 29 == 0 || (ID + 3) % 13 == 0) {
        postStr = [postStr stringByReplacingOccurrencesOfString:@"\"method\":\"" withString:@"\"method\" : \""];
    } else {
        postStr = [postStr stringByReplacingOccurrencesOfString:@"\"method\":\"" withString:@"\"method\": \""];
    }
    NSData *postDataData = [postStr dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postDataData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    AFURLSessionManager *manager = [[AFURLSessionManager alloc] init];
    manager.session.configuration.timeoutIntervalForRequest = EZNetWorkTimeoutInterval;
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    NSURLSessionTask *task = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }
        
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        
        if (error) {
            NSLog(@"deepLWebTranslate error: %@", error);
            
            BOOL useOfficialAPI = (self.authKey.length > 0) && (self.apiType == EZDeepLTranslationAPIWebFirst);
            if (useOfficialAPI) {
                [self deepLTranslate:text from:from to:to completion:completion];
                return;
            }
            
            NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            if (errorData) {
                /**
                 {
                   "error" : {
                     "code" : 1042912,
                     "message" : "Too many requests"
                   },
                   "jsonrpc" : "2.0"
                 }
                 */
                NSError *jsonError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:errorData options:kNilOptions error:&jsonError];
                if (!jsonError) {
                    NSString *errorMessage = json[@"error"][@"message"];
                    if (errorMessage.length) {
                        self.result.errorMessage = errorMessage;
                    }
                }
            }

            completion(self.result, error);
            return;
        }
        
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        NSLog(@"deepLWebTranslate cost: %.1f ms", (endTime - startTime) * 1000);

        EZDeepLTranslateResponse *deepLTranslateResponse = [EZDeepLTranslateResponse mj_objectWithKeyValues:responseObject];
        NSString *translatedText = [deepLTranslateResponse.result.texts.firstObject.text trim];
        if (translatedText) {
            NSArray *results = [translatedText toParagraphs];
            self.result.translatedResults = results;
            self.result.raw = deepLTranslateResponse;
        }
        completion(self.result, nil);
    }];
    [task resume];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}


- (NSInteger)getICount:(NSString *)translateText {
    return [[translateText componentsSeparatedByString:@"i"] count] - 1;
}

- (NSInteger)getRandomNumber {
    NSInteger rand = arc4random_uniform(89999) + 100000;
    return rand * 1000;
}

- (NSInteger)getTimeStampWithIcount:(NSInteger)iCount {
    NSInteger ts = [[NSDate date] timeIntervalSince1970] * 1000;
    if (iCount != 0) {
        iCount = iCount + 1;
        return ts - (ts % iCount) + iCount;
    } else {
        return ts;
    }
}

#pragma mark - DeepL Official Translate API

- (void)deepLTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion{
    // Docs: https://www.deepl.com/zh/docs-api/translating-text
    
    NSString *souceLangCode = [self languageCodeForLanguage:from];
    NSString *targetLangCode = [self languageCodeForLanguage:to];
    
    // DeepL api free and deepL pro api use different url host.
    BOOL isFreeKey = [self.authKey hasSuffix:@":fx"];
    NSString *host = isFreeKey ? @"https://api-free.deepl.com": @"https://api.deepl.com";
    NSString *url = [NSString stringWithFormat:@"%@/v2/translate", host];
    
    NSDictionary *params = @{
        @"auth_key" : self.authKey,
        @"text" : text,
        @"source_lang" : souceLangCode,
        @"target_lang" : targetLangCode
    };
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.session.configuration.timeoutIntervalForRequest = EZNetWorkTimeoutInterval;
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    NSURLSessionTask *task = [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        NSLog(@"deepLTranslate cost: %.1f ms", (endTime - startTime) * 1000);
        
        self.result.translatedResults = [self parseOfficialResponseObject:responseObject];
        self.result.raw = responseObject;
        completion(self.result, nil);
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }
        
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        
        NSLog(@"deepLTranslate error: %@", error);
        
        if (self.apiType == EZDeepLTranslationAPIOfficialFirst) {
            [self deepLWebTranslate:text from:from to:to completion:completion];
            return;
        }
        
        completion(self.result, error);
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}


- (NSArray<NSString *> *)parseOfficialResponseObject:(NSDictionary *)responseObject {
    /**
     {
       "translations" : [
         {
           "detected_source_language" : "EN",
           "text" : "很好"
         }
       ]
     }
     */
    NSString *translatedText = [responseObject[@"translations"] firstObject][@"text"];
    translatedText = [translatedText.trim removeExtraLineBreaks];
    NSArray *translatedTextArray = [translatedText toParagraphs];

    return translatedTextArray;
}

@end
