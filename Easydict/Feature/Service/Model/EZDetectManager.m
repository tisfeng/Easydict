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
#import "EZConfiguration+EZUserData.h"

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
        if (!ocrResult) {
            completion(self.queryModel, error);
            return;
        }
        
        self.queryModel.inputText = ocrResult.mergedText;
        EZLanguage ocrLanguage = ocrResult.from;
        if (![ocrLanguage isEqualToString:EZLanguageAuto]) {
            self.queryModel.detectedLanguage = ocrLanguage;
        }

        completion(self.queryModel, error);
    }];
}

/// Detect text language. Apple System detect, Google detect, Baidu detect.
- (void)detectText:(NSString *)queryText completion:(void (^)(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error))completion {
    if (queryText.length == 0) {
        NSString *errorString = @"detectText cannot be nil";
        NSLog(@"%@", errorString);
        completion(self.queryModel, [EZTranslateError errorWithString:errorString]);
        return;
    }
    
    [self.appleService detectText:queryText completion:^(EZLanguage appleDetectdedLanguage, NSError *_Nullable error) {
        NSMutableArray<EZLanguage> *preferredLanguages = [[EZLanguageManager.shared preferredLanguages] mutableCopy];
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
    
    // If detect success, we don't need to detect again temporarily.
    self.queryModel.needDetectLanguage = (error != nil);
    
    completion(self.queryModel, error);
}

- (void)ocr:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSImage *image = self.queryModel.OCRImage;
    if (!image) {
        NSLog(@"image cannot be nil");
        return;
    }
    
    [self.ocrService ocr:self.queryModel completion:completion];
}

/// If not designated ocr language, after ocr, we use detected language to ocr again.
- (void)deepOCR:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSImage *image = self.queryModel.OCRImage;
    if (!image) {
        NSLog(@"image cannot be nil");
        return;
    }
    
    /**
     System OCR result may be inaccurate when use auto detect language, such as:
     
     今日は国際ホッキョクグマの日
     
     But if we use Japanese to ocr again, the result will be more accurate.
     */
    
    // TODO: If ocr text is too long, maybe we could ocr only part of the image.
    // TODO: If ocr large PDF file, we should alert user to select detected language.
    [self ocr:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable ocrError) {
        if (ocrError) {
            [self handleOCRResult:ocrResult error:ocrError completion:completion];
            return;
        }
                
        // If user has specified ocr language, we don't need to detect and ocr again.
        if (self.queryModel.hasQueryFromLanguage) {
            [self handleOCRResult:ocrResult error:ocrError completion:completion];
            return;
        }
                
        /**
         !!!: Even confidence is high, such as confidence is 1.0, that just means the ocr result text is accurate, but the ocr result from langauge may be not accurate, such as 'heel', it may be detected as 'Dutch'. So we need to detect text language again.
         */
                
        NSString *ocrText = ocrResult.mergedText;
        [self detectText:ocrText completion:^(EZQueryModel *_Nonnull queryModel, NSError *_Nullable detectError) {
            if (detectError) {
                completion(ocrResult, detectError);
                return;
            }
            
            BOOL isConfidentLanguage = (ocrResult.confidence == 1.0) && [ocrResult.from isEqualToString:queryModel.detectedLanguage];
            if (isConfidentLanguage) {
                completion(ocrResult, nil);
                return;
            }
            
            [self.ocrService ocr:queryModel completion:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
                [self handleOCRResult:ocrResult error:error completion:completion];
            }];
        }];
    }];
}

- (void)handleOCRResult:(EZOCRResult *_Nullable)ocrResult error:(NSError *_Nullable)error completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    if (!error) {
        completion(ocrResult, nil);
        return;
    }
    
    /**
     Sometimes Apple OCR may fail, like Japanese text, but we have set Japanese as preferred language and OCR again when OCR result is empty, currently it seems work, but we do not guarantee it is always work in other languages.
     */
    
    if ([EZConfiguration.shared isBeta]) {
        [self.youdaoService ocr:self.queryModel completion:^(EZOCRResult *_Nullable youdaoOCRResult, NSError *_Nullable youdaoOCRError) {
            if (!youdaoOCRError) {
                completion(youdaoOCRResult, nil);
            } else {
                completion(ocrResult, error);
            }
        }];
    } else {
        completion(ocrResult, error);
    }
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
