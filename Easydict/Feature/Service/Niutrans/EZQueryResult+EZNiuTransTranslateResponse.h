//
//  EZQueryResult+EZNiuTransTranslateResponse.h
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZQueryResult.h"
#import "EZNiuTransTranslateResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZQueryResult (EZNiuTransTranslateResponse)

- (instancetype)setupWithNiuTransTranslateResponse:(EZNiuTransTranslateResponse *)niuTransTranslateResponse;

@end

NS_ASSUME_NONNULL_END
