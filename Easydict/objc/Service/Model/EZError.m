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
    NSError *error = [EZError errorWithType:EZErrorTypeUnsupportedLanguage description:showUnsupportLanguage request:nil];
    return error;
}


@implementation EZError

+ (instancetype)errorWithType:(EZErrorType)type {
    return [self errorWithType:type description:nil];
}

+ (instancetype)errorWithType:(EZErrorType)type
                  description:(nullable NSString *)description
                      request:(id _Nullable)request {
    return [self errorWithType:type description:description errorDataMessage:nil request:request];
}

+ (instancetype)errorWithType:(EZErrorType)type
                  description:(nullable NSString *)description {
    return [self errorWithType:type description:description request:nil];
}

+ (instancetype)errorWithType:(EZErrorType)type
                  description:(nullable NSString *)description
             errorDataMessage:(nullable NSString *)errorDataMessage {
    return [self errorWithType:type description:description errorDataMessage:errorDataMessage request:nil];
}

+ (instancetype)errorWithType:(EZErrorType)type
                  description:(nullable NSString *)description
             errorDataMessage:(nullable NSString *)errorDataMessage
                      request:(nullable id)request {
    NSString *errorString = nil;
    switch (type) {
        case EZErrorTypeNone:
            errorString = @"None";
            break;
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
    
    NSString *queryFailedString = NSLocalizedString(@"query_failed", nil);
    if (errorString.length) {
        errorString = [NSString stringWithFormat:@"%@, %@", queryFailedString, errorString];
    }
    if (description.length) {
        errorString = [NSString stringWithFormat:@"%@: %@", errorString, description];
    }
    
    if (type == EZErrorTypeWarppedNSError) {
        errorString = [NSString stringWithFormat:@"%@: %@", queryFailedString, description];
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (errorString) {
        [userInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
    }
    if (request) {
        [userInfo setObject:request forKey:EZTranslateErrorRequestKey];
    }
    
    EZError *error = [self errorWithDomain:EZBundleId code:type userInfo:userInfo.copy];
    error.type = type;
    error.errorDataMessage = errorDataMessage;
    
    return error;
}

+ (instancetype)timeoutError {
    NSString *description = [NSString stringWithFormat:@"Timeout of %.1f exceeded", EZNetWorkTimeoutInterval];
    return [self errorWithType:EZErrorTypeTimeout description:description];
}


#pragma mark - Wrap NSError

+ (nullable EZError *)errorWithNSError:(nullable NSError *)error {
    NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    NSString *errorDataMessage = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
    return [self errorWithNSError:error errorDataMessage:errorDataMessage];
}

+ (nullable EZError *)errorWithNSError:(nullable NSError *)error
                     errorResponseData:(nullable NSData *)errorResponseData {
    NSString *errorDataMessage = [[NSString alloc] initWithData:errorResponseData encoding:NSUTF8StringEncoding];
    EZError *ezError = [self errorWithNSError:error errorDataMessage:errorDataMessage];
    return ezError;
}

+ (nullable EZError *)errorWithNSError:(nullable NSError *)error
                      errorDataMessage:(nullable NSString *)errorDataMessage {
    if (!error || [error isKindOfClass:EZError.class]) {
        return (EZError *)error;
    }
    
    EZError *ezError = [self errorWithType:EZErrorTypeWarppedNSError 
                               description:error.localizedDescription
                          errorDataMessage:errorDataMessage];
    return ezError;
}

@end
