//
//  EZTranslateError.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTranslateError.h"

NSString *const EZTranslateErrorRequestKey = @"TranslateErrorRequestKey";
NSString *const EZTranslateErrorRequestURLKey = @"URL";
NSString *const EZTranslateErrorRequestParamKey = @"Param";
NSString *const EZTranslateErrorRequestResponseKey = @"Response";
NSString *const EZTranslateErrorRequestErrorKey = @"Error";

NSError * EZQueryNotSupportedLanguageError(EZQueryService *service) {
    NSString *to = [service languageCodeForLanguage:service.queryModel.queryTargetLanguage];
    NSString *errorMsg = service.queryModel.queryFromLanguage;
    if (!to) {
        errorMsg = service.queryModel.queryTargetLanguage;
    }
    NSError *error = EZTranslateError(EZTranslateErrorTypeUnsupportLanguage, errorMsg, nil);
    return error;
}


@implementation EZTranslateError

+ (NSError *)errorWithType:(EZTranslateErrorType)type
                   message:(NSString *_Nullable)message
                   request:(id _Nullable)request {
    NSString *errorString = nil;
    switch (type) {
        case EZTranslateErrorTypeParam:
            errorString = @"参数异常";
            break;
        case EZTranslateErrorTypeNetwork:
            errorString = @"请求异常";
            break;
        case EZTranslateErrorTypeAPI:
            errorString = @"接口异常";
            break;
        case EZTranslateErrorTypeUnsupportLanguage:
            errorString = @"不支持的语言";
            break;
        default:
            errorString = @"未知错误";
            break;
    }

    errorString = [NSString stringWithFormat:@"翻译失败，%@", errorString];
    if (message.length) {
        errorString = [NSString stringWithFormat:@"%@: %@", errorString, message];
    }
 
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
    if (request) {
        [userInfo setObject:request forKey:EZTranslateErrorRequestKey];
    }
    return [NSError errorWithDomain:@"com.izual.easydict" code:type userInfo:userInfo.copy];
}

+ (NSError *)timeoutError {
    NSString *errorString = [NSString stringWithFormat:@"Timeout of %.1f exceeded", EZNetWorkTimeoutInterval];
    NSError *error = [NSError errorWithDomain:EZBundleId code:-1 userInfo:@{NSLocalizedDescriptionKey : errorString}];
    return error;
}

@end
