//
//  EZQueryResult+EZDeepLTranslateResponse.h
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZQueryResult.h"
#import "EZDeepLTranslateResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZQueryResult (EZDeepLTranslateResponse)

- (instancetype)setupWithDeepLTranslateResponse:(EZDeepLTranslateResponse *)deepLTranslateResponse;

@end

NS_ASSUME_NONNULL_END
