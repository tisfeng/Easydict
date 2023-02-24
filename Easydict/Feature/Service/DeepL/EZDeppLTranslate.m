//
//  EZDeppLTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZDeppLTranslate.h"
#import "EZWebViewTranslator.h"
#import "EZTranslateError.h"
#import "EZQueryResult+EZDeepLTranslateResponse.h"

static NSString *kDeepLTranslateURL = @"https://www.deepl.com/translator";

@interface EZDeppLTranslate ()

@property (nonatomic, strong) EZWebViewTranslator *webViewTranslator;

@end

@implementation EZDeppLTranslate

- (instancetype)init {
    if (self = [super init]) {
        //        [self.webViewTranslator preloadURL:kDeepLTranslateURL]; // Preload webView.
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
    NSString *text = [queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    if (!from || !to) {
        return nil;
    }
    
    return [NSString stringWithFormat:@"%@#%@/%@/%@", kDeepLTranslateURL, from, to, text];
}

// Supported languages: https://www.deepl.com/zh/docs-api/translate-text/
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, @"auto",
                                        EZLanguageSimplifiedChinese, @"zh",
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
    NSArray *languages = @[ from, to ];
    if ([EZLanguageManager onlyContainsChineseLanguages:languages]) {
        [super translate:text from:from to:to completion:completion];
        return;
    }
    
    [self deepLWebTranslate:text from:from to:to completion:completion];
    //    [self webViewTranslate:completion];
}

- (void)webViewTranslate:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *wordLink = [self wordLink:self.queryModel];
    
    // Since DeepL doesn't support zh-TW, we need to convert zh-TW to zh-CN.
    if ([self.queryModel.queryFromLanguage isEqualToString:EZLanguageTraditionalChinese] &&
        ![EZLanguageManager isChineseLanguage:self.queryModel.queryTargetLanguage]) {
        EZQueryModel *queryModel = [self.queryModel copy];
        queryModel.userSourceLanguage = EZLanguageSimplifiedChinese;
        wordLink = [self wordLink:queryModel];
    }
    
    if ([self.queryModel.queryTargetLanguage isEqualToString:EZLanguageTraditionalChinese] &&
        ![EZLanguageManager isChineseLanguage:self.queryModel.queryFromLanguage]) {
        EZQueryModel *queryModel = [self.queryModel copy];
        queryModel.userTargetLanguage = EZLanguageSimplifiedChinese;
        wordLink = [self wordLink:queryModel];
    }
    
    if (!wordLink) {
        completion(self.result, EZQueryUnsupportedLanguageError(self));
        return;
    }
    
    [self.webViewTranslator queryTranslateURL:wordLink completionHandler:^(NSArray<NSString *> *_Nonnull texts, NSError *_Nonnull error) {
        if ([self.queryModel.queryTargetLanguage isEqualToString:EZLanguageTraditionalChinese]) {
            // Convert result to traditional Chinese.
            NSMutableArray *newTexts = [NSMutableArray array];
            for (NSString *text in texts) {
                NSString *newText = [text toTraditionalChineseText];
                [newTexts addObject:newText];
            }
            texts = newTexts;
        }
        
        self.result.normalResults = texts;
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


/// DeepL web translate. Ref: https://github.com/akl7777777/bob-plugin-akl-deepl-free-translate/blob/9d194783b3eb8b3a82f21bcfbbaf29d6b28c2761/src/main.js
- (void)deepLWebTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *souceLangCode = [self languageCodeForLanguage:from];
    NSString *targetLangCode = [self languageCodeForLanguage:to];
    
    NSString *url = @"https://www2.deepl.com/jsonrpc";
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
    // set timeout
    manager.session.configuration.timeoutIntervalForRequest = EZNetWorkTimeoutInterval;
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
        if (error) {
            completion(self.result, error);
            return;
        }
        
        EZDeepLTranslateResponse *deepLTranslateResponse = [EZDeepLTranslateResponse mj_objectWithKeyValues:responseObject];
        [self.result setupWithDeepLTranslateResponse:deepLTranslateResponse];
        completion(self.result, nil);
    }] resume];
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


- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"deepL not support ocr");
}

@end
