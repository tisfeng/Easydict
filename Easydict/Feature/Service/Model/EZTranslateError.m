//
//  EZTranslateError.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTranslateError.h"

NSString *const EZTranslateErrorRequestKey = @"EZTranslateErrorRequestKey";
NSString *const EZTranslateErrorRequestURLKey = @"EZTranslateErrorRequestURLKey";
NSString *const EZTranslateErrorRequestParamKey = @"EZTranslateErrorRequestParamKey";
NSString *const EZTranslateErrorRequestResponseKey = @"EZTranslateErrorRequestResponseKey";
NSString *const EZTranslateErrorRequestErrorKey = @"EZTranslateErrorRequestErrorKey";

NSError *EZQueryUnsupportedLanguageError(EZQueryService *service) {
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
            errorString = NSLocalizedString(@"error_parameter", nil);
            break;
        case EZTranslateErrorTypeNetwork:
            errorString = NSLocalizedString(@"error_network", nil);
            break;
        case EZTranslateErrorTypeAPI:
            errorString = NSLocalizedString(@"error_api", nil);
            break;
        case EZTranslateErrorTypeUnsupportLanguage:
            errorString = NSLocalizedString(@"error_unsupport_language", nil);
            break;
        default:
            errorString = NSLocalizedString(@"error_unknown", nil);
            break;
    }

    errorString = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"translate_failed", nil), errorString];
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
