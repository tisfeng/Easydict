//
//  DetectText.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZDetectManager.h"
#import "EZBaiduTranslate.h"
#import "EZAppleService.h"

@interface EZDetectManager ()

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

- (EZBaiduTranslate *)baiduService {
    if (!_baiduService) {
        _baiduService = [[EZBaiduTranslate alloc] init];
    }
    return _baiduService;
}

- (void)ocrAndDetectText:(void (^)(EZQueryModel * _Nonnull, NSError * _Nullable))completion {
    [self ocr:^(EZOCRResult * _Nullable ocrResult, NSError * _Nullable error) {
        if (error) {
            completion(self.queryModel, error);
            return;
        }
        
        self.queryModel.queryText = ocrResult.mergedText;
        [self detectText:completion];
    }];
}

- (void)detectText:(void (^)(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error))completion {
    NSString *queryText = self.queryModel.queryText;
    if (queryText.length == 0) {
        NSLog(@"queryText cannot be nil");
        return;
    }
    
    [self.detectTextService detect:queryText completion:^(EZLanguage language, NSError * _Nullable error) {        
        if ([language isEqualToString:EZLanguageAuto]) {
            [self.baiduService detect:queryText completion:^(EZLanguage  _Nonnull language, NSError * _Nullable error) {
                NSLog(@"baidu detected: %@", language); // Apple detect 123 will fail.

                self.queryModel.detectedLanguage = language;
                
                completion(self.queryModel, error);
            }];
            return;
        }
        
        self.queryModel.detectedLanguage = language;
        
        completion(self.queryModel, error);
    }];
}

- (void)ocr:(void (^)(EZOCRResult * _Nullable, NSError * _Nullable))completion {
    NSImage *image = self.queryModel.ocrImage;
    if (!image) {
        NSLog(@"image cannot be nil");
        return;
    }
    
    [self.ocrService ocr:self.queryModel completion:completion];
}

@end
