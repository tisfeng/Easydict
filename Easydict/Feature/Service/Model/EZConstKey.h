//
//  EZConstKey.h
//  Easydict
//
//  Created by tisfeng on 2023/6/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZEnumTypes.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZBetaFeatureKey = @"EZBetaFeatureKey";

static NSString *const EZDictionaryKey = @"Dictionary";

static NSString *const EZOpenAIAPIKey = @"EZOpenAIAPIKey";
static NSString *const EZOpenAITranslationKey = @"EZOpenAITranslationKey";
static NSString *const EZOpenAIDictionaryKey = @"EZOpenAIDictionaryKey";
static NSString *const EZOpenAISentenceKey = @"EZOpenAISentenceKey";

static NSString *const EZOpenAIServiceUsageStatusKey = @"EZOpenAIServiceUsageStatusKey";

static NSString *const EZOpenAIDomainKey = @"EZOpenAIDomainKey";
static NSString *const EZOpenAIModelKey = @"EZOpenAIModelKey";
static NSString *const EZOpenAIFullRequestUrlKey = @"EZOpenAIFullRequestUrlKey";

static NSString *const EZDeepLAuthKey = @"EZDeepLAuthKey";


@interface EZConstKey : NSObject

+ (NSString *)constkey:(NSString *)key windowType:(EZWindowType)windowType;

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType;

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType windowType:(EZWindowType)windowType;

@end

NS_ASSUME_NONNULL_END
