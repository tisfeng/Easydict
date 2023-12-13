//
//  EZVolcanoTranslate.m
//  Easydict
//
//  Created by tisfeng on 2022/12/23.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZVolcanoTranslate.h"
#import "EZWebViewTranslator.h"

static NSString *kVolcanoLTranslateURL = @"https://translate.volcengine.com";

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
        //        NSString *selector = @".translate-area-result"; // old desktop
        
        // WTF, why is the result of the volcano translation so disgusting...
        _webViewTranslator.querySelector = @".translate-dictionary-content-target-text"; // dict;
        
        NSString *delayQuerySelector = @".arco-textarea.text-area.text-area-focus.text-area-display"; // non-dict, 2023.1.13
        _webViewTranslator.delayQuerySelector = delayQuerySelector;
        
        // a[0] is source text, a[1] is translated text.
        _webViewTranslator.delayJsCode = [NSString stringWithFormat:@"Array.from(document.querySelectorAll('%@')).slice(-1).map(el=>el.textContent)", delayQuerySelector];
        
        _webViewTranslator.delayRetryCount = 15;
        _webViewTranslator.queryModel = self.queryModel;
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
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    NSString *from = [self languageCodeForLanguage:queryModel.queryFromLanguage];
    NSString *to = [self languageCodeForLanguage:queryModel.queryTargetLanguage];
    
    // Since volcano web translation max query length is 800, so we have to truncate the text.
    NSString *queryText = [self.queryModel.queryText trimToMaxLength:800].encode;
    
    return [NSString stringWithFormat:@"%@?category=&home_language=zh&source_language=%@&target_language=%@&text=%@", kVolcanoLTranslateURL, from, to, queryText];
}

- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, @"auto",
                                        EZLanguageSimplifiedChinese, @"zh",
                                        EZLanguageTraditionalChinese, @"zh-Hant",
                                        EZLanguageClassicalChinese, @"lzh",
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

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *, NSError *_Nullable))completion {
    [self webViewTranslate:completion];
}

- (void)webViewTranslate:(nonnull void (^)(EZQueryResult *, NSError *_Nullable))completion {
    // https://translate.volcengine.com/?category=&home_language=zh&source_language=en&target_language=zh&text=good
    // https://translate.volcengine.com/translate?category=&home_language=zh&source_language=en&target_language=zh&text=good
        
    NSString *wordLink = [self wordLink:self.queryModel];
    
    [self.webViewTranslator queryTranslateURL:wordLink completionHandler:^(NSArray<NSString *> *_Nonnull texts, NSError *_Nonnull error) {
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }
       
        self.result.translatedResults = texts;
        completion(self.result, error);
    }];
    
    mm_weakify(self);
    [self.queryModel setStopBlock:^{
        mm_strongify(self);
        [self.webViewTranslator resetWebView];
    } serviceType:self.serviceType];
    
    // https://translate.volcengine.com/web/translate/v1/?msToken=&X-Bogus=DFSzKwGLQDGhFUIXSkg53N7TlqSz&_signature=_02B4Z6wo00001JPEP6AAAIDDBxJkrN0CktiT1DsAAEdZbuaHXanY5YK83lzLs2IvC-TGG2SrwAfASYu0RlxzNxrvOYDTyy2LHOGiN98QnTNZfEC6O0BSwWWTr5KNbw3TykBrdkDs6PsVqDcOc9
    
    // https://translate.volcengine.com/web/dict/detail/v1/?msToken=&X-Bogus=DFSzswVmQDGy-4zDSZ1KKKIkirE-&_signature=_02B4Z6wo00001WxCnygAAIDADDchOBSP91VsQpuAADjVa6
    
    // ???: Why does this method cause a persistent memory leak? But DeepL does not?
    //        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    //        NSString *monitorURL = @"https://translate.volcengine.com/web/translate/v1/?msToken";
    //        monitorURL = @"https://translate.volcengine.com/web/dict/detail/v1";
    //
    //        [self.webViewTranslator monitorBaseURLString:monitorURL
    //                                             loadURL:self.wordLink
    //                                   completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
    //            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    //            NSLog(@"API deepL cost: %.1f ms", (endTime - startTime) * 1000); // cost ~2s
    //
    //            //        NSLog(@"deepL responseObject: %@", responseObject);
    //        }];
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"volcano not support ocr");
}

@end
