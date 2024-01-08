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
static NSString *const EZOpenAIEndPointKey = @"EZOpenAIEndPointKey";
static NSString *const EZOpenAIModelKey = @"EZOpenAIModelKey";


static NSString *const EZDeepLAuthKey = @"EZDeepLAuthKey";
static NSString *const EZDeepLTranslateEndPointKey = @"EZDeepLTranslateEndPointKey";

static NSString *const EZBingCookieKey = @"EZBingCookieKey";
static NSString *const EZNiuTransAPIKey = @"EZNiuTransAPIKey";
static NSString *const EZCaiyunToken = @"EZCaiyunToken";
static NSString *const EZTencentSecretId = @"EZTencentSecretId";
static NSString *const EZTencentSecretKey = @"EZTencentSecretKey";

static NSString *const EZAliAccessKeyId = @"EZAliAccessKeyId";
static NSString *const EZAliAccessKeySecret = @"EZAliAccessKeySecret";

@interface EZConstKey : NSObject

+ (NSString *)constkey:(NSString *)key windowType:(EZWindowType)windowType;

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType;

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType windowType:(EZWindowType)windowType;

@end

NS_ASSUME_NONNULL_END
