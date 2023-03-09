//
//  EZQueryResult+EZDeepLTranslateResponse.m
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZQueryResult+EZDeepLTranslateResponse.h"

@implementation EZQueryResult (EZDeepLTranslateResponse)

- (instancetype)setupWithDeepLTranslateResponse:(EZDeepLTranslateResponse *)deepLTranslateResponse {
    self.raw = deepLTranslateResponse;
    NSString *firstResult = deepLTranslateResponse.result.texts.firstObject.text;
    if (firstResult) {
        self.normalResults = @[ firstResult.trim ];
    }

    return self;
}

@end
