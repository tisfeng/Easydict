//
//  EZOpenAIService.h
//  Easydict
//
//  Created by tisfeng on 2023/2/24.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZQueryService.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *EZOpenAIKey = @"EZOpenAIKey";
static NSString *EZOpenAITranslationKey = @"EZOpenAITranslationKey";
static NSString *EZOpenAIDictionaryKey = @"EZOpenAIDictionaryKey";
static NSString *EZOpenAISentenceKey = @"EZOpenAISentenceKey";

@interface EZOpenAIService : EZQueryService

@end

NS_ASSUME_NONNULL_END
