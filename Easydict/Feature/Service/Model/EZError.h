//
//  EZTranslateError.h
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EZQueryService;

NS_ASSUME_NONNULL_BEGIN

/// 报错时的请求信息
extern NSString *const EZTranslateErrorRequestKey;
extern NSString *const EZTranslateErrorRequestURLKey;
extern NSString *const EZTranslateErrorRequestParamKey;
extern NSString *const EZTranslateErrorRequestResponseKey;
extern NSString *const EZTranslateErrorRequestErrorKey;

typedef NS_ENUM(NSUInteger, EZErrorType) {
    EZErrorTypeNone,
    EZErrorTypeAPI, // 接口异常
    EZErrorTypeParam, // 参数异常
    EZErrorTypeNetwork, // 网络异常
    EZErrorTypeTimeout, // 超时
    EZErrorTypeUnsupportedLanguage, // 不支持的语言
    EZErrorTypeNoResultsFound, // 未查询到结果
    EZErrorTypeInsufficientQuota, // 内置 API key 额度不足
};

/// 错误，不支持的语言
FOUNDATION_EXPORT NSError *EZQueryUnsupportedLanguageError(EZQueryService *service);


@interface EZError : NSObject

+ (NSError *)errorWithType:(EZErrorType)type
                   message:(NSString *_Nullable)message
                   request:(id _Nullable)request;

+ (NSError *)timeoutError;

+ (NSError *)errorWithString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
