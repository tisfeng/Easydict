//
//  EZDeppLTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZDeppLTranslate.h"
#import "EZWebViewTranslator.h"

static NSString *kDeepLTranslateURL = @"https://www.deepl.com/translator";

@interface EZDeppLTranslate ()

@property (nonatomic, strong) EZWebViewTranslator *webViewTranslator;

@end

@implementation EZDeppLTranslate

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
    return @"DeepL 翻译";
}

- (NSString *)link {
    return kDeepLTranslateURL;
}

// https://www.deepl.com/translator#en/zh/good
- (NSString *)wordLink {
    NSString *from = [self languageCodeForLanguage:self.queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:self.queryModel.autoTargetLanguage];
    NSString *text = [self.queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    return [NSString stringWithFormat:@"%@#%@/%@/%@", kDeepLTranslateURL, from, to, text];
}

// Supported languages: https://www.deepl.com/zh/docs-api/translate-text/
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
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
                                        EZLanguageEstonian, @"",
                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult * _Nullable, NSError * _Nullable))completion {
    [self webViewTranslate:completion];
}

- (void)webViewTranslate: (nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    self.result = [[EZQueryResult alloc] init];
    [self.webViewTranslator queryURL:self.wordLink success:^(NSString * _Nonnull translatedText) {
        self.result.normalResults = @[translatedText];
        completion(self.result, nil);
    } failure:^(NSError * _Nonnull error) {
        completion(nil, error);
    }];
}

@end
