//
//  DetectText.m
//  Easydict
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZDetectManager.h"
#import "EZBaiduTranslate.h"
#import "EZAppleService.h"
#import "EZGoogleTranslate.h"

@interface EZDetectManager ()

@property (nonatomic, strong) EZGoogleTranslate *googleService;
@property (nonatomic, strong) EZBaiduTranslate *baiduService;

@end

@implementation EZDetectManager

+ (instancetype)managerWithModel:(EZQueryModel *)model {
    EZDetectManager *manager = [[EZDetectManager alloc] init];
    manager.queryModel = model;

    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.detectTextService = [[EZAppleService alloc] init];
        self.ocrService = self.detectTextService;
    }
    return self;
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

- (void)ocrAndDetectText:(void (^)(EZQueryModel *_Nonnull, NSError *_Nullable))completion {
    [self ocr:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        if (error) {
            completion(self.queryModel, error);
            return;
        }

        self.queryModel.queryText = ocrResult.mergedText;
        [self detectText:completion];
    }];
}

/// Detect text language. Apple System detect > Google detect > Baidu detect.
- (void)detectText:(void (^)(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error))completion {
    NSString *queryText = self.queryModel.queryText;
    if (queryText.length == 0) {
        NSLog(@"detectText cannot be nil");
        
        // !!!: There are some problems with the system OCR, for example, it may return nil when recognizing Japanese.
        NSError *error = [EZTranslateError errorWithString:NSLocalizedString(@"ocr_result_is_empty", nil)];
        completion(self.queryModel, error);
        return;
    }

    [self.detectTextService detectText:queryText completion:^(EZLanguage appleDetectdedLanguage, NSError *_Nullable error) {
        BOOL isPreferredLanguage = [[EZLanguageManager systemPreferredLanguages] containsObject:appleDetectdedLanguage];
        if (isPreferredLanguage) {
            [self handleDetectedLanguage:appleDetectdedLanguage error:error completion:completion];
            return;
        }

        // If language is not preferred, try to use google detect.
        [self.googleService detectText:queryText completion:^(EZLanguage _Nonnull language, NSError *_Nullable error) {
            NSLog(@"google detected: %@", language);
            if (!error) {
                [self handleDetectedLanguage:language error:error completion:completion];
                return;
            }

            // If google detect failed, use baidu detect.
            [self.baiduService detectText:queryText completion:^(EZLanguage _Nonnull language, NSError *_Nullable error) {
                NSLog(@"baidu detected: %@", language);
                EZLanguage detectedLanguage = appleDetectdedLanguage;
                if (!error) {
                    detectedLanguage = language;
                }
                [self handleDetectedLanguage:detectedLanguage error:error completion:completion];
            }];
        }];
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
