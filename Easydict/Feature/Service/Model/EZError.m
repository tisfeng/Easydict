//
//  EZTranslateError.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZError.h"
#import "EZQueryService.h"

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
    NSError *error = [EZError errorWithType:EZErrorTypeUnsupportedLanguage message:showUnsupportLanguage request:nil];
    return error;
}


@implementation EZError

+ (instancetype)errorWithType:(EZErrorType)type
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
        case EZErrorTypeNoResultsFound:
            errorString = NSLocalizedString(@"no_results_found", nil);
            break;
        case EZErrorTypeInsufficientQuota:
            errorString = NSLocalizedString(@"error_insufficient_quota", nil);
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
    
    EZError *error = [EZError errorWithDomain:EZBundleId code:type userInfo:userInfo.copy];
    error.type = type;
    
    return error;
}

+ (instancetype)errorWithType:(EZErrorType)type message:(NSString *)message {
    return [self errorWithType:type message:message request:nil];
}

+ (instancetype)timeoutError {
    NSString *errorString = [NSString stringWithFormat:@"Timeout of %.1f exceeded", EZNetWorkTimeoutInterval];
    return [self errorWithType:EZErrorTypeTimeout message:errorString request:nil];
}

@end
