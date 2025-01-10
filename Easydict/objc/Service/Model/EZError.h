////
////  EZTranslateError.h
////  Easydict
////
////  Created by tisfeng on 2022/12/1.
////  Copyright © 2022 izual. All rights reserved.
////
//
//#import <Foundation/Foundation.h>
//
//@class EZQueryService;
//
//NS_ASSUME_NONNULL_BEGIN
//
///// 报错时的请求信息
//extern NSString *const EZTranslateErrorRequestKey;
//extern NSString *const EZTranslateErrorRequestURLKey;
//extern NSString *const EZTranslateErrorRequestParamKey;
//extern NSString *const EZTranslateErrorRequestResponseKey;
//extern NSString *const EZTranslateErrorRequestErrorKey;
//
//typedef NS_ENUM(NSUInteger, EZQueryErrorType) {
//    EZQueryErrorTypeNone, // 预留参数，暂未使用
//
//    EZQueryErrorTypeApi, // 接口异常
//    EZQueryErrorTypeParam, // 参数异常
//    EZQueryErrorTypeTimeout, // 超时
//    EZQueryErrorTypeUnsupportedLanguage, // 不支持的语言
//    EZQueryErrorTypeNoResult, // 未查询到结果
//    EZQueryErrorTypeInsufficientQuota, // 内置 API key 额度不足
//    EZQueryErrorTypeWarppedNSError, // Warp NSError
//    EZQueryErrorTypeMissingAPIKey, // 没有设置 API Key
//};
//
///// 错误，不支持的语言
//FOUNDATION_EXPORT NSError *EZQueryUnsupportedLanguageError(EZQueryService *service);
//
//
//@interface EZQueryError : NSError
//
//@property (nonatomic, assign) EZQueryErrorType type;
//@property (nonatomic, copy, nullable) NSString *errorDataMessage;
//
//+ (instancetype)errorWithType:(EZQueryErrorType)type;
//
//+ (instancetype)errorWithType:(EZQueryErrorType)type
//                      message:(nullable NSString *)description;
//
//+ (instancetype)errorWithType:(EZQueryErrorType)type
//                      message:(nullable NSString *)description
//             errorDataMessage:(nullable NSString *)errorDataMessage;
//
//+ (instancetype)errorWithType:(EZQueryErrorType)type
//                      message:(nullable NSString *)description
//                      request:(id _Nullable)request;
//
//+ (instancetype)errorWithType:(EZQueryErrorType)type
//                      message:(nullable NSString *)description
//             errorDataMessage:(nullable NSString *)errorDataMessage
//                      request:(nullable id)request;
//
//+ (instancetype)timeoutError;
//
//
//#pragma mark - Wrap NSError
//
//+ (nullable EZQueryError *)errorWithNSError:(nullable NSError *)error;
//+ (nullable EZQueryError *)errorWithNSError:(nullable NSError *)error errorResponseData:(nullable NSData *)errorResponseData;
//+ (nullable EZQueryError *)errorWithNSError:(nullable NSError *)error errorDataMessage:(nullable NSString *)errorMessage;
//
//@end
//
//NS_ASSUME_NONNULL_END
