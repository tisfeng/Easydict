//
//  EZNiuTransTranslate.m
//  Easydict
//
//  Created by BigGuang97 on 2023/11/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZNiuTransTranslate.h"
#import "NSArray+EZChineseText.h"
#import "EZNiuTransTranslateResponse.h"
#import "FWEncryptorAES.h"

static NSString *kNiuTransTranslateURL = @"https://api.niutrans.com/NiuTransServer/translation";


@interface EZNiuTransTranslate ()

@property (nonatomic, copy) NSString *apiKey;

@end

@implementation EZNiuTransTranslate

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (NSString *)apiKey {
    // This is a test APIKey, please do not abuse it. It is recommended to go to the official website to apply for a personal APIKey.
    NSString *defaultEncryptedAPIKey = @"O5C+RKrWBR5GLMtqiOHlyS6Ib9D8JPY7aN8/S49gwmRYZNcxpbQ6eeNso6KoJVeR";
    NSString *defaultAPIKey = [FWEncryptorAES decryptText:defaultEncryptedAPIKey key:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:EZNiuTransAPIKey];
    if (apiKey.length == 0) {
        apiKey = defaultAPIKey;
    }
    return apiKey;
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
                                        EZLanguageHebrew, @"he",
                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *, NSError *_Nullable))completion {
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:YES from:from to:to completion:completion]) {
        return;
    }
    
    [self niuTransTranslate:text from:from to:to completion:completion];
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"NiuTrans not support ocr");
}

#pragma mark - NiuTrans API

- (void)niuTransTranslate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSString *souceLangCode = [self languageCodeForLanguage:from];
    NSString *targetLangCode = [self languageCodeForLanguage:to];
    
    // NiuTrans API free and NiuTrans pro API use different URL host
    NSString *host = @"https://api.niutrans.com";
    NSString *url = [NSString stringWithFormat:@"%@/NiuTransServer/translation", host];
    
    NSDictionary *params = @{
        @"apikey" : self.apiKey,
        @"src_text" : text,
        @"from" : souceLangCode,
        @"to" : targetLangCode,
        @"source" : @"Easydict"
    };
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer=[AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/plain", nil];
    manager.session.configuration.timeoutIntervalForRequest = EZNetWorkTimeoutInterval;
    NSURLSessionTask *task = [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        EZNiuTransTranslateResponse *niuTransTranslateResult = [EZNiuTransTranslateResponse mj_objectWithKeyValues:responseObject];
        NSString *translatedText = niuTransTranslateResult.tgtText;
        // When translated text has multiple paragraphs, it will have an extra line break at the end, which we need to remove.
        translatedText = [translatedText stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
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
