//
//  EZOpenAILikeService.h
//  Easydict
//
//  Created by phlpsong on 2024/2/26.
//  Copyright © 2024 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZQueryService.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kEZLanguageWenYanWen = @"文言文";

NS_SWIFT_NAME(OpenAILikeService)
@interface EZOpenAILikeService : EZQueryService

@property (nonatomic, copy, readonly) NSString *apiKey;
@property (nonatomic, copy, readonly) NSString *endPoint;
@property (nonatomic, copy, readonly) NSString *model;

@property (nonatomic, copy) NSString *defaultAPIKey;
@property (nonatomic, copy) NSString *defaultModel;


@end

NS_ASSUME_NONNULL_END
