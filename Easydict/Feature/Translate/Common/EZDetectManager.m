//
//  DetectText.m
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZDetectManager.h"
#import "BaiduTranslate.h"

@interface EZDetectManager ()

@end

@implementation EZDetectManager

+ (instancetype)managerWithModel:(EZQueryModel *)model {
    EZDetectManager *manager = [[EZDetectManager alloc] init];
    manager.queryModel = model;
    
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _service = [[BaiduTranslate alloc] init];
    }
    return self;
}

- (void)detect:(void (^)(EZQueryModel * _Nonnull queryModel, NSError * _Nullable error))completion {
    NSString *queryText = self.queryModel.queryText;
    if (queryText.length == 0) {
        NSLog(@"queryText cannot be nil");
        return;
    }
    
    [self.service detect:queryText completion:^(Language lang, NSError * _Nullable error) {
        self.queryModel.sourceLanguage = lang;
        completion(self.queryModel, error);
    }];
}

@end
