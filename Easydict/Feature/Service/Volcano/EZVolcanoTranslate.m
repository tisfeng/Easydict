//
//  EZVolcanoTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZVolcanoTranslate.h"
#import "EZWebViewTranslator.h"

static NSString *kVolcanoLTranslateURL = @"https://translate.volcengine.com/translate";

@interface EZVolcanoTranslate ()

@property (nonatomic, strong) EZWebViewTranslator *webViewTranslator;

@end

@implementation EZVolcanoTranslate

- (instancetype)init {
    if (self = [super init]) {
        //        [self.webViewTranslator preloadURL:kVolcanoLTranslateURL]; // Preload webView.
    }
    return self;
}

- (EZWebViewTranslator *)webViewTranslator {
    if (!_webViewTranslator) {
        _webViewTranslator = [[EZWebViewTranslator alloc] init];
        
        // Note that the desktop and mobile versions of the volcano have different web elements
        //        NSString *selector = @"[contenteditable=false] [data-slate-string]"; // mobile
        NSString *selector = @".translate-area-result"; // desktop
        _webViewTranslator.querySelector = selector;
    }
    return _webViewTranslator;
}


#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeVolcano;
}

- (NSString *)name {
    return NSLocalizedString(@"volcano_translate", nil);
}

- (NSString *)link {
    return kVolcanoLTranslateURL;
}

// https://translate.volcengine.com/translate?category=&home_language=zh&source_language=detect&target_language=zh&text=good
- (NSString *)wordLink {
    NSString *from = [self languageCodeForLanguage:self.queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:self.queryModel.queryTargetLanguage];
    NSString *text = [self.queryModel.queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    return [NSString stringWithFormat:@"%@?category=&home_language=zh&source_language=%@&target_language=%@&text=%@", kVolcanoLTranslateURL, from, to, text];
}

- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, @"auto",
                                        EZLanguageSimplifiedChinese, @"zh",
                                        EZLanguageTraditionalChinese, @"zh-Hant",
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

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    [self webViewTranslate:completion];
}

- (void)webViewTranslate:(nonnull void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    [self.webViewTranslator queryTranslateURL:self.wordLink completionHandler:^(NSArray<NSString *> *_Nonnull texts, NSError *_Nonnull error) {
        self.result.normalResults = texts;
        completion(self.result, error);
    }];
    
    // https://translate.volcengine.com/web/translate/v1/?msToken=&X-Bogus=DFSzKwGLQDGhFUIXSkg53N7TlqSz&_signature=_02B4Z6wo00001JPEP6AAAIDDBxJkrN0CktiT1DsAAEdZbuaHXanY5YK83lzLs2IvC-TGG2SrwAfASYu0RlxzNxrvOYDTyy2LHOGiN98QnTNZfEC6O0BSwWWTr5KNbw3TykBrdkDs6PsVqDcOc9
    
    // ???: Why does this method cause a persistent memory leak? But DeepL does not?
    //    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    //    NSString *monitorURL = @"https://translate.volcengine.com/web/translate/v1/?msToken";
    //    [self.webViewTranslator monitorBaseURLString:monitorURL
    //                                         loadURL:self.wordLink
    //                               completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
    //        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    //        NSLog(@"API deepL cost: %.1f ms", (endTime - startTime) * 1000); // cost ~2s
    //
    //        //        NSLog(@"deepL responseObject: %@", responseObject);
    //    }];
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"volcano not support ocr");
}

@end
