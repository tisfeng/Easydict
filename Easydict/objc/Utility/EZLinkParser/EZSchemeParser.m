//
//  EZLinkParser.m
//  Easydict
//
//  Created by tisfeng on 2023/2/25.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZSchemeParser.h"

@interface EZSchemeParser ()

- (BOOL)isParameterlessConfirmationRequest:(NSURLComponents *)components;

@end

@implementation EZSchemeParser

#pragma mark - Public

/// Open Easydict URL Scheme.
- (void)openURLScheme:(NSString *)URLScheme completion:(void (^)(BOOL isSuccess, NSString *_Nullable returnValue, NSString *_Nullable actionKey))completion {
    NSString *text = [URLScheme ns_trim];
    
    if (![self isEasydictScheme:text]) {
        completion(NO, @"Invalid Easydict Scheme", nil);
        return;
    }
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:text];
    NSString *action = urlComponents.host;
    NSString *query = urlComponents.query;
    NSDictionary *parameterDict = [self extractQueryParametersFromURLComponents:urlComponents];
    
    NSArray *allowedActions = @[
        EZWriteKeyValueKey,
        EZReadValueOfKeyKey,
        EZResetUserDefaultsDataKey,
        EZSaveUserDefaultsDataToDownloadFolderKey,
    ];

    if (![allowedActions containsObject:action]) {
        if ([action isEqualToString:EZQueryKey]) {
            [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:URLScheme]];
            completion(YES, nil, nil);
        } else {
            completion(NO, @"Invalid Easydict Action", nil);
        }
    
        return;
    }
    
    BOOL isSuccess = NO;
    NSString *returnValue = @"Failed";
    if ([action isEqualToString:EZWriteKeyValueKey]) {
        isSuccess = [self writeKeyValues:parameterDict];
        returnValue = isSuccess ? @"Write Success" : @"Write Failed";
    } else if ([action isEqualToString:EZReadValueOfKeyKey]) {
        returnValue = [self readValueOfKey:query];
        isSuccess = returnValue ? YES : NO;
        if (isSuccess) {
            [returnValue copyToPasteboard];
        }
    } else if ([action isEqualToString:EZResetUserDefaultsDataKey]) {
        if (![self isParameterlessConfirmationRequest:urlComponents]) {
            completion(NO, @"Invalid Reset Request", action);
            return;
        }
        [EZConfigurationSchemeActionCoordinator.shared requestResetConfirmation];
        isSuccess = YES;
        returnValue = @"Confirmation Required";
    } else if ([action isEqualToString:EZSaveUserDefaultsDataToDownloadFolderKey]) {
        if (![self isParameterlessConfirmationRequest:urlComponents]) {
            completion(NO, @"Invalid Export Request", action);
            return;
        }
        [EZConfigurationSchemeActionCoordinator.shared requestEncryptedExport];
        isSuccess = YES;
        returnValue = @"Encrypted Backup Opened";
    }
    
    completion(isSuccess, returnValue, action);
}

/// Confirmation-only actions accept no payload-bearing URL components.
- (BOOL)isParameterlessConfirmationRequest:(NSURLComponents *)components {
    return components.user.length == 0 &&
        components.password.length == 0 &&
        components.port == nil &&
        components.path.length == 0 &&
        components.query.length == 0 &&
        components.fragment.length == 0;
}

- (BOOL)isEasydictScheme:(NSString *)text {
    NSString *urlString = [text ns_trim];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:urlString];
    NSString *scheme = urlComponents.scheme;
    NSArray *schemes = @[EZAppScheme, EZAppDebugScheme];
    return [schemes containsObject:scheme];
}

- (BOOL)isWriteActionKey:(NSString *)actionKey {
    NSArray *writeKeys = @[
        EZWriteKeyValueKey,
    ];
    
    return [writeKeys containsObject:actionKey];
}

/// Write a non-sensitive key value to NSUserDefaults.
- (BOOL)writeKeyValues:(NSDictionary *)keyValues {
    if (keyValues.count == 0) {
        return NO;
    }

    // Validate and type the complete batch before mutating defaults so a rejected item cannot
    // leave a partially applied configuration behind. Credential denial intentionally runs first.
    NSMutableDictionary<NSString *, id> *normalizedValues = [NSMutableDictionary dictionary];
    for (NSString *key in keyValues) {
        NSString *value = keyValues[key];
        if ([EZConfigurationItemRegistry isSensitiveKey:key] ||
            [EZConfigurationItemRegistry isEndpointKey:key] ||
            ![EZConfigurationItemRegistry isSchemeAutomatableKey:key]) {
            return NO;
        }
        id normalizedValue = [EZConfigurationItemRegistry schemeValueForKey:key rawValue:value];
        if (!normalizedValue) {
            return NO;
        }
        normalizedValues[key] = normalizedValue;
    }

    MyConfiguration *config = [MyConfiguration shared];
    BOOL wasBetaEnabled = config.beta;
    [normalizedValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    }];
    if (!wasBetaEnabled && config.beta) {
        [MyConfiguration.shared enableBetaFeaturesIfNeeded];
    }
    return YES;
}

/// Read a non-sensitive value from NSUserDefaults.
- (nullable NSString *)readValueOfKey:(NSString *)key {
    if ([EZConfigurationItemRegistry isSensitiveKey:key] ||
        ![EZConfigurationItemRegistry isSchemeAutomatableKey:key]) {
        return nil;
    }
    // Endpoint automation is intentionally write-only. Even an otherwise valid HTTPS endpoint
    // can carry provider-specific secrets in its path or query, while legacy saved values may
    // contain URL userinfo. Never copy endpoint values to the pasteboard through URL Scheme.
    if ([EZConfigurationItemRegistry isEndpointKey:key]) {
        return nil;
    }
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if ([value isKindOfClass:NSString.class]) {
        return value;
    }
    if ([value isKindOfClass:NSNumber.class]) {
        return [value stringValue];
    }
    return nil;
}


#pragma mark -

- (NSDictionary *)extractQueryParametersFromURLString:(NSString *)urlString {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:urlString];
    NSDictionary *queryParameters = [self extractQueryParametersFromURLComponents:urlComponents];
    return queryParameters;
}

// 解析 URL 中的查询参数
- (NSDictionary *)extractQueryParametersFromURLComponents:(NSURLComponents *)urlComponents {
    NSMutableDictionary *queryParameters = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *queryItem in urlComponents.queryItems) {
        NSString *key = queryItem.name;
        NSString *value = queryItem.value;
        
        if (key && value) {
            queryParameters[key] = value;
        }
    }
    
    return [queryParameters copy];
}

#pragma mark -

/// Return key values dict from key-value pairs: key1=value1&key2=value2&key3=value3
- (NSDictionary *)getKeyValues:(NSString *)text {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *keyValueArray = [text componentsSeparatedByString:@"&"];
    for (NSString *keyValue in keyValueArray) {
        NSArray *array = [keyValue componentsSeparatedByString:@"="];
        if (array.count == 2) {
            NSString *key = array[0];
            NSString *value = array[1];
            dict[key] = value;
        }
    }
    return dict;
}

@end
