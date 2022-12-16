//
//  DetectText.h
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZQueryModel.h"
#import "EZQueryService.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZDetectManager : NSObject

@property (nonatomic, strong) EZQueryModel *queryModel;
@property (nonatomic, strong) EZQueryService *detectTextService;
@property (nonatomic, strong) EZQueryService *ocrService;

+ (instancetype)managerWithModel:(EZQueryModel *)model;

- (void)ocrAndDetectText:(void (^)(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error))completion;

- (void)detectText:(void (^)(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error))completion;
- (void)ocr:(void (^)(EZOCRResult * _Nullable, NSError * _Nullable))completion ;

@end

NS_ASSUME_NONNULL_END
