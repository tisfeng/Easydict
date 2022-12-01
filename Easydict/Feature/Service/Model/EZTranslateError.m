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
            break;
    }
    if (message.length) {
        if (errorString.length) {
            errorString = [NSString stringWithFormat:@"%@: %@", errorString, message];
        } else {
            errorString = message;
        }
    }
    if (!errorString.length) {
        errorString = @"未知错误";
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
    if (request) {
        [userInfo setObject:request forKey:EZTranslateErrorRequestKey];
    }
    return [NSError errorWithDomain:@"com.izual.easydict" code:type userInfo:userInfo.copy];
}

@end
