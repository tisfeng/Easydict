//
//  DetectText.h
//  Easydict
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZQueryModel.h"
//#import "EZAppleService.h"
//#import "Easydict-Swift.h"
#import "EZQueryService.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZDetectManager : NSObject

@property (nonatomic, strong) EZQueryModel *queryModel;
//@property (nonatomic, strong) EZAppleService *appleService;
@property (nonatomic, strong) EZQueryService *ocrService;

+ (instancetype)managerWithModel:(EZQueryModel *)model;

- (instancetype)initWithModel:(EZQueryModel *)model;

- (void)ocrAndDetectText:(void (^)(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error))completion;

- (void)detectText:(NSString *)queryText completion:(void (^)(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error))completion;

- (void)ocr:(void (^)(EZOCRResult * _Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
