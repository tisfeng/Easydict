//
//  EZTranslateError.h
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define EZTranslateError(type, msg, req) [EZTranslateError errorWithType:(type) message:(msg)request:(req)]

/// 报错时的请求信息
extern NSString *const EZTranslateErrorRequestKey;
extern NSString *const EZTranslateErrorRequestURLKey;
extern NSString *const EZTranslateErrorRequestParamKey;
extern NSString *const EZTranslateErrorRequestResponseKey;
extern NSString *const EZTranslateErrorRequestErrorKey;

typedef NS_ENUM(NSUInteger, EZTranslateErrorType) {
    /// 参数异常
    EZTranslateErrorTypeParam,
    /// 请求异常
    EZTranslateErrorTypeNetwork,
    /// 接口异常
    EZTranslateErrorTypeAPI,
    /// 不支持的语言
    EZTranslateErrorTypeUnsupportLanguage,
};


@interface EZTranslateError : NSObject

+ (NSError *)errorWithType:(EZTranslateErrorType)type
                   message:(NSString *_Nullable)message
                   request:(id _Nullable)request;

@end

NS_ASSUME_NONNULL_END
