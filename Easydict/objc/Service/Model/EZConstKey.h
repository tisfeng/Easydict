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

static NSString *const EZServiceUsageStatusKey = @"ServiceUsageStatus";
static NSString *const EZTranslationKey = @"Translation";
static NSString *const EZDictionaryKey = @"Dictionary";
static NSString *const EZSentenceKey = @"Sentence";

// OpenAI
static NSString *const EZOpenAIAPIKey = @"EZOpenAIAPIKey";
static NSString *const EZOpenAIEndPointKey = @"EZOpenAIEndPointKey";
static NSString *const EZOpenAITranslationKey = @"EZOpenAITranslationKey";
static NSString *const EZOpenAIDictionaryKey = @"EZOpenAIDictionaryKey";
static NSString *const EZOpenAISentenceKey = @"EZOpenAISentenceKey";
static NSString *const EZOpenAIServiceUsageStatusKey = @"EZOpenAIServiceUsageStatusKey";
static NSString *const EZOpenAIModelKey = @"EZOpenAIModelKey";
static NSString *const EZOpenAIAvailableModelsKey = @"EZOpenAIAvailableModelsKey";
static NSString *const EZOpenAIValidModelsKey = @"EZOpenAIValidModelsKey";

// Custom OpenAI
static NSString *const EZCustomOpenAINameKey = @"EZCustomOpenAINameKey";
static NSString *const EZCustomOpenAIEndPointKey = @"EZCustomOpenAIEndPointKey";
static NSString *const EZCustomOpenAIAPIKey = @"EZCustomOpenAIAPIKey";
static NSString *const EZCustomOpenAITranslationKey = @"EZCustomOpenAITranslationKey";
static NSString *const EZCustomOpenAIDictionaryKey = @"EZCustomOpenAIDictionaryKey";
static NSString *const EZCustomOpenAISentenceKey = @"EZCustomOpenAISentenceKey";
static NSString *const EZCustomOpenAIServiceUsageStatusKey = @"EZCustomOpenAIServiceUsageStatusKey";
static NSString *const EZCustomOpenAIAvailableModelsKey = @"EZCustomOpenAIAvailableModelsKey";
static NSString *const EZCustomOpenAIModelKey = @"EZCustomOpenAIModelKey";
static NSString *const EZCustomOpenAIValidModelsKey = @"EZCustomOpenAIValidModelsKey";

// // Built-in AI
static NSString *const EZBuiltInAIModelKey = @"EZBuiltInAIModelKey";

// Gemini
static NSString *const EZGeminiAPIKey = @"EZGeminiAPIKey";
static NSString *const EZGeminiTranslationKey = @"EZGeminiTranslationKey";
static NSString *const EZGeminiDictionaryKey = @"EZGeminiDictionaryKey";
static NSString *const EZGeminiSentenceKey = @"EZGeminiSentenceKey";
static NSString *const EZGeminiServiceUsageStatusKey = @"EZGeminiServiceUsageStatusKey";
static NSString *const EZGeminiModelKey = @"EZGeminiModelKey";
static NSString *const EZGeminiAvailableModelsKey = @"EZGeminiAvailableModelsKey";
static NSString *const EZGeminiValidModelsKey = @"EZGeminiValidModelsKey";

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
