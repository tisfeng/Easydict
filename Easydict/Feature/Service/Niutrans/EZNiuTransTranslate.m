//
//  EZNiuTransTranslate.m
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZNiuTransTranslate.h"
#import "EZWebViewTranslator.h"
// #import "EZTranslateError.h"
#import "NSArray+EZChineseText.h"
#import "EZNiuTransTranslateResponse.h"

static NSString *kNiuTransTranslateURL = @"https://api.niutrans.com/NiuTransServer/translation";


@interface EZNiuTransTranslate ()

@property (nonatomic, strong) EZWebViewTranslator *webViewTranslator;

@property (nonatomic, copy) NSString *authKey;

@end

@implementation EZNiuTransTranslate

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
    NSString *authKey = [[NSUserDefaults standardUserDefaults] stringForKey:EZNiuTransAuthKey] ?: @"";
    return authKey;
}


#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeNiuTrans;
}

- (NSString *)name {
    return NSLocalizedString(@"niuTrans_translate", nil);
}

- (NSString *)link {
    return kNiuTransTranslateURL;
}


// https://niutrans.com/documents/contents/trans_text#accessMode
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *from = [self languageCodeForLanguage:queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:queryModel.queryTargetLanguage];
    NSString *text = [queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *encodedText = [text stringByReplacingOccurrencesOfString:@"/" withString:@"%5C%2F"];
    
    if (!from || !to) {
        return nil;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@#%@/%@/%@", kNiuTransTranslateURL, from, to, encodedText];
    
    return url;
}

// Supported languages: https://niutrans.com/documents/contents/trans_text#languageList
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, @"auto",
                                        EZLanguageSimplifiedChinese, @"zh",
                                        EZLanguageTraditionalChinese, @"cht",
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
                                        EZLanguageFilipino, @"fil",
                                        EZLanguageKhmer, @"km",
                                        EZLanguageLao, @"lo",
                                        EZLanguageBengali, @"bn",
                                        EZLanguageBurmese, @"my",
                                        EZLanguageNorwegian, @"no",
                                        EZLanguageSerbian, @"sr",
                                        EZLanguageCroatian, @"hr",
                                        EZLanguageMongolian, @"mn",
                                        EZLanguageHebrew, @"et",
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
    
    [self niuTransTranslate:text from:from to:to completion:callback];
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"NiuTrans not support ocr");
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

#pragma mark - NiuTrans API

- (void)niuTransTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *souceLangCode = [self languageCodeForLanguage:from];
    NSString *targetLangCode = [self languageCodeForLanguage:to];
    
    // NiuTrans api free and NiuTrans pro api use different url host
    NSString *host = @"https://api.niutrans.com";
    NSString *url = [NSString stringWithFormat:@"%@/NiuTransServer/translation", host];
    
    NSDictionary *params = @{
        @"apikey" : self.authKey,
        @"src_text" : text,
        @"from" : souceLangCode,
        @"to" : targetLangCode
    };
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.session.configuration.timeoutIntervalForRequest = EZNetWorkTimeoutInterval;
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    NSURLSessionTask *task = [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        NSLog(@"NiuTransTranslate cost: %.1f ms", (endTime - startTime) * 1000);
        
        EZNiuTransTranslateResponse *niuTransTranslateResult = [EZNiuTransTranslateResponse mj_objectWithKeyValues:responseObject];
        
        NSString *translatedText = niuTransTranslateResult.tgtText;
        if (translatedText) {
            self.result.translatedResults = [translatedText toParagraphs];
            self.result.raw = responseObject;
            completion(self.result, nil);
        } else {
            NSString *errorCode = niuTransTranslateResult.errorCode;
            NSString *errorMsg = niuTransTranslateResult.errorMsg;
            if (errorCode.length) {
                NSString *message = errorCode;
                if (errorMsg) {
                    message = [NSString stringWithFormat:@"%@, %@", errorCode, errorMsg];
                }
                NSError *error = [EZTranslateError errorWithType:EZErrorTypeAPI
                                                         message:message
                                                         request:task.currentRequest];
                completion(self.result, error);
            }
        }
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        NSLog(@"NiuTransTranslate error: %@", error);
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }
        
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        
        NSLog(@"NiuTransTranslate error: %@", error);
        
        completion(self.result, error);
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}

@end
