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
- (NSString *)wordLink {
    NSString *from = [self languageCodeForLanguage:self.queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:self.queryModel.queryTargetLanguage];
    NSString *text = [self.queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
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
                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    [self webViewTranslate:completion];
}

- (void)webViewTranslate:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (!self.wordLink) {
        NSString *to = [self languageCodeForLanguage:self.queryModel.queryTargetLanguage];
        
        NSString *errorMsg = self.queryModel.queryFromLanguage;
        if (!to) {
            errorMsg = self.queryModel.queryTargetLanguage;
        }
        
        NSError *error = EZTranslateError(EZTranslateErrorTypeUnsupportLanguage, errorMsg, nil);
        completion(self.result, error);
        return;
    }
    
    [self.webViewTranslator queryTranslateURL:self.wordLink completionHandler:^(NSArray<NSString *> *_Nonnull texts, NSError *_Nonnull error) {
        self.result.normalResults = texts;
        completion(self.result, error);
    }];
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSString *monitorURL = @"https://www2.deepl.com/jsonrpc?method=LMT_handle_jobs";
    [self.webViewTranslator monitorBaseURLString:monitorURL
                                         loadURL:self.wordLink
                               completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        NSLog(@"API deepL cost: %.1f ms", (endTime - startTime) * 1000); // cost ~2s
        
        //        NSLog(@"deepL responseObject: %@", responseObject);
    }];
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"deepL not support ocr");
}

@end
