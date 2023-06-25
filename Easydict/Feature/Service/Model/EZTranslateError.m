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
    EZLanguage unsupportLanguage = service.queryModel.queryFromLanguage;
    if (!to) {
        unsupportLanguage = service.queryModel.queryTargetLanguage;
    }
    
    NSString *showUnsupportLanguage = [EZLanguageManager.shared showingLanguageName:unsupportLanguage];
    
    NSError *error = EZTranslateError(EZErrorTypeUnsupportedLanguage, showUnsupportLanguage, nil);
    return error;
}


@implementation EZTranslateError

+ (NSError *)errorWithType:(EZErrorType)type
                   message:(NSString *_Nullable)message
                   request:(id _Nullable)request {
    NSString *errorString = nil;
    switch (type) {
        case EZErrorTypeParam:
            errorString = NSLocalizedString(@"error_parameter", nil);
            break;
        case EZErrorTypeNetwork:
            errorString = NSLocalizedString(@"error_network", nil);
            break;
        case EZErrorTypeAPI:
            errorString = NSLocalizedString(@"error_api", nil);
            break;
        case EZErrorTypeUnsupportedLanguage:
            errorString = NSLocalizedString(@"error_unsupport_language", nil);
            break;
        default:
            errorString = NSLocalizedString(@"error_unknown", nil);
            break;
    }

    errorString = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"query_failed", nil), errorString];
    if (message.length) {
        errorString = [NSString stringWithFormat:@"%@: %@", errorString, message];
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
    if (request) {
        [userInfo setObject:request forKey:EZTranslateErrorRequestKey];
    }
    return [NSError errorWithDomain:EZBundleId code:type userInfo:userInfo.copy];
}

+ (NSError *)timeoutError {
    NSString *errorString = [NSString stringWithFormat:@"Timeout of %.1f exceeded", EZNetWorkTimeoutInterval];
    return [self errorWithString:errorString];
}

+ (NSError *)errorWithString:(NSString *)string {
    NSString *errorString = string ?: @"error";
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:EZBundleId code:-1 userInfo:userInfo];
    return error;
}

@end
