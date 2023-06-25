//
//  EZError.m
//  Easydict
//
//  Created by tisfeng on 2023/5/7.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZError.h"
#import "EZQueryService.h"

@implementation EZError

+ (instancetype)errorWithType:(EZErrorType)type message:(NSString *)message {
    NSString *localizedDescription = @"";
    switch (type) {
        case EZErrorTypeParam:
            localizedDescription = NSLocalizedString(@"error_parameter", nil);
            break;
        case EZErrorTypeNetwork:
            localizedDescription = NSLocalizedString(@"error_network", nil);
            break;
        case EZErrorTypeAPI:
            localizedDescription = NSLocalizedString(@"error_api", nil);
            break;
        case EZErrorTypeTimeout:
            localizedDescription = [NSString stringWithFormat:@"Timeout of %.1f exceeded", EZNetWorkTimeoutInterval];
            break;
        case EZErrorTypeUnsupportedLanguage:
            localizedDescription = NSLocalizedString(@"error_unsupport_language", nil);
            break;
        default:
            break;
    }
    
    NSString *errorString = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"query_failed", nil), localizedDescription];
     if (message.length) {
         errorString = [NSString stringWithFormat:@"%@: %@", errorString, message];
     }
    
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: localizedDescription};
    EZError *error = [self errorWithDomain:EZBundleId code:type userInfo:userInfo];
    error.errorType = type;
    
    return error;
}

+ (instancetype)errorWithType:(EZErrorType)type {
    return [self errorWithType:type message:nil];;
}

+ (instancetype)errorWithString:(NSString *)string {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: string};
    return [self errorWithDomain:EZBundleId code:0 userInfo:userInfo];
}

+ (instancetype)errorWithUnsupportedLanguageService:(EZQueryService *)service {
    NSString *to = [service languageCodeForLanguage:service.queryModel.queryTargetLanguage];
    EZLanguage unsupportLanguage = service.queryModel.queryFromLanguage;
    if (!to) {
        unsupportLanguage = service.queryModel.queryTargetLanguage;
    }
    
    NSString *showUnsupportLanguage = [EZLanguageManager.shared showingLanguageName:unsupportLanguage];
    
    EZError *error = [self errorWithType:EZErrorTypeUnsupportedLanguage message:showUnsupportLanguage];
    
    return error;
}


@end
