//
//  EZLinkParser.m
//  Easydict
//
//  Created by tisfeng on 2023/2/25.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZSchemeParser.h"
#import "EZOpenAIService.h"
#import "EZYoudaoTranslate.h"
#import "EZServiceTypes.h"
#import "EZDeepLTranslate.h"
#import "EZConfiguration+EZUserData.h"
#import "EZConfiguration.h"
#import "EZLocalStorage.h"

@implementation EZSchemeParser

#pragma mark - Public

/// Open Easydict URL Scheme.
- (void)openURLScheme:(NSString *)URLScheme completion:(void (^)(BOOL isSuccess, NSString *_Nullable returnValue, NSString *_Nullable actionKey))completion {
    NSString *text = [URLScheme trim];
    
    if (![self isEasydictScheme:text]) {
        completion(NO, @"Invalid Easydict Scheme", nil);
        return;
    }
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:text];
    NSString *action = urlComponents.host;
    NSString *query = urlComponents.query;
    NSDictionary *parameterDict = [self extractQueryParametersFromURLComponents:urlComponents];
    
    NSDictionary *actionDict = [self allowedActionSelectorDict];
    NSArray *allowedActions = actionDict.allKeys;

    if (![allowedActions containsObject:action]) {
        completion(NO, @"Invalid Easydict Action", nil);
        return;
    }
    
    BOOL isSuccess = NO;
    NSString *returnValue = @"Failed";
    NSString *selectorString = actionDict[action];
    SEL selector = NSSelectorFromString(selectorString);
    
    if (selector == @selector(writeKeyValues:)) {
        isSuccess = [self writeKeyValues:parameterDict];
        returnValue = isSuccess ? @"Write Success" : @"Write Failed";
    } else if (selector == @selector(readValueOfKey:)) {
        returnValue = [self readValueOfKey:query];
        isSuccess = returnValue ? YES : NO;
        if (isSuccess) {
            [returnValue copyToPasteboard];
        }
    } else if (selector == @selector(resetUserDefaultsData)) {
        [self resetUserDefaultsData];
        isSuccess = YES;
        returnValue = @"Reset Success";
    } else if (selector == @selector(saveUserDefaultsDataToDownloadFolder)) {
        [self saveUserDefaultsDataToDownloadFolder];
        isSuccess = YES;
        returnValue = @"Save Success";
    }
    
    completion(isSuccess, returnValue, action);
}

- (BOOL)isEasydictScheme:(NSString *)text {
    NSString *urlString = [text trim];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:urlString];
    NSString *scheme = urlComponents.scheme;
    return [scheme isEqualToString:EZEasydictScheme];
}

- (BOOL)isWriteActionKey:(NSString *)actionKey {
    NSArray *writeKeys = @[
        EZWriteKeyValueKey,
        EZResetUserDefaultsDataKey,
    ];
    
    return [writeKeys containsObject:actionKey];
}

#pragma mark -

/// Allowed action keys.
- (NSDictionary<NSString *, NSString *> *)allowedActionSelectorDict {
    return @{
        EZWriteKeyValueKey : NSStringFromSelector(@selector(writeKeyValues:)),
        EZReadValueOfKeyKey : NSStringFromSelector(@selector(readValueOfKey:)),
        EZResetUserDefaultsDataKey : NSStringFromSelector(@selector(resetUserDefaultsData)),
        EZSaveUserDefaultsDataToDownloadFolderKey : NSStringFromSelector(@selector(saveUserDefaultsDataToDownloadFolder)),
    };
}

/// Write key value to NSUserDefaults. easydict://writeKeyValue?EZOpenAIAPIKey=sk-zob
- (BOOL)writeKeyValues:(NSDictionary *)keyValues {
    BOOL handled = NO;
    for (NSString *key in keyValues) {
        NSString *value = keyValues[key];
        handled = [self enabledReadWriteKey:key];
        if (handled) {
            EZConfiguration *config = [EZConfiguration shared];
            BOOL isBeta = config.isBeta;
            
            [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
            
            // If enabling beta feature, setup beta features.
            if (!isBeta && config.isBeta) {
                [EZConfiguration.shared enableBetaFeaturesIfNeeded];
            }
        }
    }
    return handled;
}

/// Read value of key from NSUserDefaults. easydict://readValueOfKey?EZOpenAIAPIKey
- (nullable NSString *)readValueOfKey:(NSString *)key {
    if ([self enabledReadWriteKey:key]) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:key];
    } else {
        return nil;
    }
}

- (BOOL)enabledReadWriteKey:(NSString *)key {
    BOOL handled = NO;
    if ([self.allowedReadWriteKeys containsObject:key]) {
        handled = YES;
    }
    
    if ([EZConfiguration.shared isBeta]) {
        NSArray *allServiceTypes = [EZServiceTypes.shared allServiceTypes];
        // easydict://writeKeyValue?Google-IntelligentQueryTextType=0
        NSArray *arr = [key componentsSeparatedByString:@"-"];
        if (arr.count) {
            NSString *keyString = arr.firstObject;
            if ([allServiceTypes containsObject:keyString] || [self.allowedReadWriteKeys containsObject:keyString]) {
                handled = YES;
            }
        }
    }
    return handled;
}

- (void)resetUserDefaultsData {
    // easydict://resetUserDefaultsData
    [EZConfiguration.shared resetUserDefaultsData];
    
    [EZLocalStorage destroySharedInstance];
    [EZConfiguration destroySharedInstance];
}

- (void)saveUserDefaultsDataToDownloadFolder {
    // easydict://saveUserDefaultsDataToDownloadFolder
    [EZConfiguration.shared saveUserDefaultsDataToDownloadFolder];
}


/// Return allowed write keys to NSUserDefaults.
- (NSArray *)allowedReadWriteKeys {
    /**
     easydict://writeKeyValue?EZBetaFeatureKey=1
     
     easydict://writeKeyValue?EZOpenAIAPIKey=sk-zob
     easydict://writeKeyValue?EZOpenAIServiceUsageStatusKey=1
     easydict://writeKeyValue?EZOpenAIDomainKey=api.openai.com
     easydict://readValueOfKey?EZOpenAIDomainKey
     easydict://writeKeyValue?EZOpenAIModelKey=gpt-3.5-turbo
     easydict://writeKeyValue?EZOpenAIDictionaryKey=0
     easydict://writeKeyValue?EZOpenAISentenceKey=0
     
     easydict://writeKeyValue?EZDeepLAuthKey=xxx
     easydict://writeKeyValue?EZDeepLTranslationAPIKey=1
     
     // Youdao TTS
     easydict://writeKeyValue?EZDefaultTTSServiceKey=Youdao
     
     // Intelligent Query Mode, enable mini window
     easydict://writeKeyValue?IntelligentQueryMode-window1=1
     
     // Intelligent Query
     easydict://writeKeyValue?Google-IntelligentQueryTextType=5  // translation | sentence
     easydict://writeKeyValue?Youdao-IntelligentQueryTextType=2  // dictionary
     */
    
    NSArray *readWriteKeys = @[
        EZBetaFeatureKey,
        
        EZOpenAIAPIKey,
        EZOpenAIDictionaryKey,
        EZOpenAISentenceKey,
        EZOpenAIServiceUsageStatusKey,
        EZOpenAIDomainKey,
        EZOpenAIModelKey,
        EZOpenAIFullRequestUrlKey,
        
        EZYoudaoTranslationKey,
        EZYoudaoDictionaryKey,
        
        EZDeepLAuthKey,
        EZDeepLTranslationAPIKey,
        
        EZDefaultTTSServiceKey,
        
        EZIntelligentQueryModeKey,
    ];
    
    return readWriteKeys;
}

- (NSArray *)allowedExecuteActionKeys {
    NSArray *actionKeys = @[

        // easydict://saveUserDefaultsDataToDownloadFolder
        EZSaveUserDefaultsDataToDownloadFolderKey,
        
        // easydict://resetUserDefaultsData
        EZResetUserDefaultsDataKey,
        
    ];
    
    return actionKeys;;
}

- (void)restartApplication {
    // 获取当前应用的 NSApplication 实例
    NSApplication *application = [NSApplication sharedApplication];
    
    // 请求应用退出并重启
    [application terminate:nil];
    
    // 使用 NSTask 执行重启命令
    NSString *launchPath = @"/usr/bin/open";
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSArray *arguments = @[bundlePath];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:launchPath];
    [task setArguments:arguments];
    [task launch];
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

- (NSString *)keyValuesOfServiceType:(EZServiceType)serviceType key:(NSString *)key value:(NSString *)value {
    /**
     easydict://writeKeyValue?ServiceType=OpenAI&ServiceUsageStatus=1
     
     easydict://writeKeyValue?OpenAIServiceUsageStatus=1
     
     easydict://writeKeyValue?OpenAIQueryServiceType=1
     */
    NSString *keyValueString = @"";
    
    NSArray *allowdKeyNames = @[
        EZServiceUsageStatusKey,
        EZQueryTextTypeKey,
    ];
    
    NSArray *allServiceTypes = [EZServiceTypes.shared allServiceTypes];
    
    BOOL validKey = [allServiceTypes containsObject:serviceType] && [allowdKeyNames containsObject:key];
    
    if (validKey) {
        NSString *keyString = [NSString stringWithFormat:@"%@%@", serviceType, key];
        keyValueString = [NSString stringWithFormat:@"%@=%@", keyString, value];
    }
    
    return keyValueString;
}

@end
