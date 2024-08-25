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

static NSString *const EZDeepLAuthKey = @"EZDeepLAuthKey";
static NSString *const EZDeepLTranslateEndPointKey = @"EZDeepLTranslateEndPointKey";

static NSString *const EZBingCookieKey = @"EZBingCookieKey";
static NSString *const EZNiuTransAPIKey = @"EZNiuTransAPIKey";
static NSString *const EZCaiyunToken = @"EZCaiyunToken";
static NSString *const EZTencentSecretId = @"EZTencentSecretId";
static NSString *const EZTencentSecretKey = @"EZTencentSecretKey";
static NSString *const EZGeminiAPIKey = @"EZGeminiAPIKey";
static NSString *const EZIntelligentQueryModeKey = @"IntelligentQueryMode";
static NSString *const EZAliAccessKeyId = @"EZAliAccessKeyId";
static NSString *const EZAliAccessKeySecret = @"EZAliAccessKeySecret";
static NSString *const EZAliServiceApiTypeKey = @"EZAliServiceApiTypeKey";

static NSString *const EZBaiduAppId = @"EZBaiduAppId";
static NSString *const EZBaiduSecretKey = @"EZBaiduSecretKey";
static NSString *const EZBaiduServiceApiTypeKey = @"EZBaiduServiceApiTypeKey";

static NSString *const EZVolcanoAccessKeyID = @"EZVolcanoAccessKeyID";
static NSString *const EZVolcanoSecretAccessKey = @"EZVolcanoSecretAccessKey";

@interface EZConstKey : NSObject

+ (NSString *)constkey:(NSString *)key windowType:(EZWindowType)windowType;

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType;

+ (NSString *)constkey:(NSString *)key serviceType:(EZServiceType)serviceType windowType:(EZWindowType)windowType;

@end

NS_ASSUME_NONNULL_END
