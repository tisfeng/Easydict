//
//  TranslateError.h
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define TranslateError(type, msg, req) [TranslateError errorWithType:(type) message:(msg) request:(req)]

/// 报错时的请求信息
extern NSString * const TranslateErrorRequestKey;
extern NSString * const TranslateErrorRequestURLKey;
extern NSString * const TranslateErrorRequestParamKey;
extern NSString * const TranslateErrorRequestResponseKey;
extern NSString * const TranslateErrorRequestErrorKey;

typedef NS_ENUM(NSUInteger, TranslateErrorType) {
    /// 参数异常
    TranslateErrorTypeParam,
    /// 请求异常
    TranslateErrorTypeNetwork,
    /// 接口异常
    TranslateErrorTypeAPI,
    /// 不支持的语言
    TranslateErrorTypeUnsupportLanguage,
};

@interface TranslateError : NSObject

+ (NSError *)errorWithType:(TranslateErrorType)type
                   message:(NSString * _Nullable)message
                   request:(id _Nullable)request;

@end

NS_ASSUME_NONNULL_END
