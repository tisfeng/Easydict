//
//  DetectText.h
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslateLanguage.h"
#import "EZQueryModel.h"
#import "TranslateService.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZDetectManager : NSObject

@property (nonatomic, strong) EZQueryModel *queryModel;
@property (nonatomic, strong) TranslateService *detectTextService;
@property (nonatomic, strong) TranslateService *ocrService;

+ (instancetype)managerWithModel:(EZQueryModel *)model;

- (void)ocrAndDetectText:(void (^)(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error))completion;

- (void)detectText:(void (^)(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error))completion;
- (void)ocr:(void (^)(OCRResult * _Nullable, NSError * _Nullable))completion ;

@end

NS_ASSUME_NONNULL_END
