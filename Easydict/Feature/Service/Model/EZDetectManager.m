//
//  DetectText.m
//  Easydict
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZDetectManager.h"
#import "EZBaiduTranslate.h"
#import "EZGoogleTranslate.h"
#import "EZConfiguration.h"
#import "EZYoudaoTranslate.h"

@interface EZDetectManager ()

@property (nonatomic, strong) EZGoogleTranslate *googleService;
@property (nonatomic, strong) EZBaiduTranslate *baiduService;
@property (nonatomic, strong) EZYoudaoTranslate *youdaoService;

@end

@implementation EZDetectManager

+ (instancetype)managerWithModel:(EZQueryModel *)model {
    EZDetectManager *manager = [[EZDetectManager alloc] init];
    manager.queryModel = model;
    
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (EZAppleService *)appleService {
    if (!_appleService) {
        _appleService = [[EZAppleService alloc] init];
    }
    return _appleService;
}

- (EZQueryService *)ocrService {
    if (!_ocrService) {
        _ocrService = self.appleService;
    }
    return _ocrService;
}

- (EZGoogleTranslate *)googleService {
    if (!_googleService) {
        _googleService = [[EZGoogleTranslate alloc] init];
    }
    return _googleService;
}

- (EZBaiduTranslate *)baiduService {
    if (!_baiduService) {
        _baiduService = [[EZBaiduTranslate alloc] init];
    }
    return _baiduService;
}

- (EZYoudaoTranslate *)youdaoService {
    if (!_youdaoService) {
        _youdaoService = [[EZYoudaoTranslate alloc] init];
    }
    return _youdaoService;
}

#pragma mark -

- (void)ocrAndDetectText:(void (^)(EZQueryModel *_Nonnull, NSError *_Nullable))completion {
    [self deepOCR:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        self.queryModel.queryText = ocrResult.mergedText;
        completion(self.queryModel, error);
    }];
}

/// Detect text language. Apple System detect, Google detect, Baidu detect.
- (void)detectText:(NSString *)queryText completion:(void (^)(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error))completion {
    if (queryText.length == 0) {
        NSLog(@"detectText cannot be nil");
        completion(self.queryModel, nil);
        return;
    }
    
    [self.appleService detectText:queryText completion:^(EZLanguage appleDetectdedLanguage, NSError *_Nullable error) {
        NSMutableArray<EZLanguage> *preferredLanguages = [[EZLanguageManager systemPreferredLanguages] mutableCopy];
        EZLanguageDetectOptimize languageDetectOptimize = EZConfiguration.shared.languageDetectOptimize;
        
        // Add English and Chinese to the preferred language list, in general, sysytem detect English and Chinese is relatively accurate, so we don't need to use google or baidu to detect again.
        [preferredLanguages addObjectsFromArray:@[
            EZLanguageEnglish,
            EZLanguageSimplifiedChinese,
            EZLanguageTraditionalChinese,
        ]];
        
        BOOL isPreferredLanguage = [preferredLanguages containsObject:appleDetectdedLanguage];
        if (isPreferredLanguage || languageDetectOptimize == EZLanguageDetectOptimizeNone) {
            [self handleDetectedLanguage:appleDetectdedLanguage error:error completion:completion];
            return;
        }
        
        void (^baiduDetectBlock)(NSString *) = ^(NSString *queryText) {
            [self.baiduService detectText:queryText completion:^(EZLanguage _Nonnull language, NSError *_Nullable error) {
                EZLanguage detectedLanguage = appleDetectdedLanguage;
                if (!error) {
                    detectedLanguage = language;
                    NSLog(@"baidu detected: %@", language);
                } else {
                    MMLogInfo(@"baidu detect error: %@", error);
                }
                [self handleDetectedLanguage:detectedLanguage error:error completion:completion];
            }];
        };
        
        if (languageDetectOptimize == EZLanguageDetectOptimizeBaidu) {
            baiduDetectBlock(queryText);
            return;
        }
        
        if (languageDetectOptimize == EZLanguageDetectOptimizeGoogle) {
            [self.googleService detectText:queryText completion:^(EZLanguage _Nonnull language, NSError *_Nullable error) {
                if (!error) {
                    NSLog(@"google detected: %@", language);
                    [self handleDetectedLanguage:language error:error completion:completion];
                    return;
                }
                
                MMLogInfo(@"google detect error: %@", error);
                
                // If google detect failed, use baidu detect.
                baiduDetectBlock(queryText);
            }];
            return;
        }
    }];
}

- (void)handleDetectedLanguage:(EZLanguage)language
                         error:(NSError *_Nullable)error
                    completion:(void (^)(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error))completion {
    self.queryModel.detectedLanguage = language;
    completion(self.queryModel, error);
}

- (void)ocr:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSImage *image = self.queryModel.ocrImage;
    if (!image) {
        NSLog(@"image cannot be nil");
        return;
    }
    
    [self.ocrService ocr:self.queryModel completion:completion];
}

/// If not designated ocr language, after ocr, we use detected language to ocr again.
- (void)deepOCR:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSImage *image = self.queryModel.ocrImage;
    if (!image) {
        NSLog(@"image cannot be nil");
        return;
    }
    
    BOOL retryOCR = [self.queryModel.detectedLanguage isEqualToString:EZLanguageAuto] && [self.queryModel.userSourceLanguage isEqualToString:EZLanguageAuto];
    
    [self ocr:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        if (!error && retryOCR) {
            NSString *ocrText = ocrResult.mergedText;
            [self detectText:ocrText completion:^(EZQueryModel *_Nonnull queryModel, NSError *_Nullable ocrError) {
                if (!error) {
                    [self.ocrService ocr:queryModel completion:completion];
                } else {
                    completion(ocrResult, nil);
                }
            }];
        } else {
            // TODO: try to deep OCR ?
            // TODO: try to use an other online OCR service? like detect text.
            [self.youdaoService ocr:self.queryModel completion:^(EZOCRResult *_Nullable youdaoOcrResult, NSError *_Nullable youdaoOcrError) {
                if (!youdaoOcrError) {
                    completion(youdaoOcrResult, nil);
                } else {
                    completion(ocrResult, error);
                }
            }];
        }
    }];
}

/// Check if has proxy.
- (BOOL)checkIfHasProxy {
    CFDictionaryRef proxies = SCDynamicStoreCopyProxies(NULL);
    
    CFTypeRef httpProxy = CFDictionaryGetValue(proxies, kSCPropNetProxiesHTTPProxy);
    NSNumber *httpEnable = (__bridge NSNumber *)(CFDictionaryGetValue(proxies, kSCPropNetProxiesHTTPEnable));
    
    if (httpProxy && httpEnable && [httpEnable integerValue]) {
        return YES;
    }
    
    return NO;
}

@end
