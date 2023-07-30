//
//  EZError.h
//  Easydict
//
//  Created by tisfeng on 2023/5/7.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EZQueryService;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EZErrorType) {
    EZErrorTypeNone,
    EZErrorTypeAPI, // 接口异常
    EZErrorTypeParam, // 参数异常
    EZErrorTypeNetwork, // 网络异常
    EZErrorTypeTimeout, // 超时
    EZErrorTypeUnsupportedLanguage, // 不支持的语言
    EZErrorTypeNoResultsFound, // 未查询到结果
};


@interface EZError : NSError

@property (nonatomic, assign) EZErrorType errorType;

/// supplementary error message, from API response data.
@property (nonatomic, copy, nullable) NSString *errorMessage;

+ (instancetype)errorWithType:(EZErrorType)type
                      message:(NSString *_Nullable)message;

+ (instancetype)errorWithType:(EZErrorType)type;

+ (instancetype)errorWithString:(NSString *)string;

+ (instancetype)errorWithUnsupportedLanguageService:(EZQueryService *)service;

@end

NS_ASSUME_NONNULL_END
