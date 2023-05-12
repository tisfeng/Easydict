//
//  EZLinkParser.m
//  Easydict
//
//  Created by tisfeng on 2023/2/25.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZSchemaParser.h"
#import "EZOpenAIService.h"
#import "EZYoudaoTranslate.h"
#import "EZServiceTypes.h"
#import "EZDeepLTranslate.h"

/// Easydict Schema: easydict://
static NSString *const kEasydictSchema = @"easydict://";

@implementation EZSchemaParser

#pragma mark - Write dict to NSUserDefaults

/// Open Easydict URL Schema.
- (void)openURLSchema:(NSString *)URLSchema completion:(void (^)(BOOL isSuccess, NSString *_Nullable returnValue))completion {
    NSString *text = [URLSchema trim];
    
    if (![self isEasydictSchema:text]) {
        completion(NO, @"Invalid Easydict Schema");
        return;
    }
    
    // Remove easydict://
    text = [text substringFromIndex:kEasydictSchema.length];
    
    NSString *action = [self actionFromText:text];
    if (!action) {
        completion(NO, @"Invalid Easydict Action");
        return;
    }
    
    BOOL isSuccess = NO;
    NSString *returnValue = @"Failed";
    
    /**
     easydict://readValueOfKey?EZOpenAIAPIKey
     
     text: easydict://writeKeyValue?EZOpenAIAPIKey=sk-5DJ2bQxdT
     Remove action: writeKeyValue
     
     param: EZOpenAIAPIKey=sk-5DJ2bQxdT
     */
    NSString *param = [text substringFromIndex:action.length + 1];
    
    NSString *selectorString = [self allowedActionSelectorDict][action];
    SEL selector = NSSelectorFromString(selectorString);
    if (selector == @selector(writeKeyValue:)) {
        isSuccess = [self writeKeyValue:param];
        returnValue = isSuccess ? @"Write Success" : @"Write Failed";
    } else if (selector == @selector(readValueOfKey:)) {
        returnValue = [self readValueOfKey:param];
        isSuccess = returnValue ? YES : NO;
        if (isSuccess) {
            [returnValue copyToPasteboard];
        }
    }
    
    completion(isSuccess, returnValue);
}

/// Check if text started with easydict://
- (BOOL)isEasydictSchema:(NSString *)text {
    return [[text trim] hasPrefix:kEasydictSchema];
}

/// Get action from text. readValueOfKey: or writeKeyValue:
- (NSString *)actionFromText:(NSString *)text {
    NSArray<NSString *> *components = [text componentsSeparatedByString:@"?"];
    if (components.count > 0) {
        NSString *action = components.firstObject;
        NSArray *allowedActions = [self allowedActionSelectorDict].allKeys;
        if ([allowedActions containsObject:action]) {
            return action;
        }
    }
    return nil;
}

/// Allowed read and write keys.
- (NSDictionary<NSString *, NSString *> *)allowedActionSelectorDict {
    return @{
        @"writeKeyValue" : NSStringFromSelector(@selector(writeKeyValue:)),
        @"readValueOfKey": NSStringFromSelector(@selector(readValueOfKey:)),
    };
}

/// Write key value to NSUserDefaults. easydict://writeKeyValue?EZOpenAIAPIKey=sk-zob
- (BOOL)writeKeyValue:(NSString *)text {
    NSDictionary *keyValue = [self getKeyValues:text];
    BOOL handled = NO;
    for (NSString *key in keyValue) {
        NSString *value = keyValue[key];
        if ([self.allowedReadWriteKeys containsObject:key]) {
            [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
            handled = YES;
        }
    }
    return handled;
}

/// Read value of key from NSUserDefaults. easydict://readValueOfKey?EZOpenAIAPIKey
- (nullable NSString *)readValueOfKey:(NSString *)key {
    if ([self.allowedReadWriteKeys containsObject:key]) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:key];
    } else {
        return nil;
    }
}

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

/// Return allowed write keys to NSUserDefaults.
- (NSArray *)allowedReadWriteKeys {
    /**
     easydict://writeKeyValue?EZBetaFeatureKey=1
     
     easydict://writeKeyValue?EZOpenAIAPIKey=sk-zob
     easydict://writeKeyValue?EZOpenAIServiceUsageStatusKey=1
     easydict://writeKeyValue?EZOpenAIDomainKey=api.openai.com
     easydict://readValueOfKey?EZOpenAIDomainKey
     easydict://writeKeyValue?EZOpenAIModelKey=gpt-3.5-turbo
     
     easydict://writeKeyValue?EZDeepLAuthKey=xxx
     easydict://writeKeyValue?EZDeepLTranslationAPIKey=1
     
     // Youdao TTS
     easydict://writeKeyValue?EZDefaultTTSServiceKey=Youdao
     */
    
    return @[
        EZBetaFeatureKey,
        
        EZOpenAIAPIKey,
        EZOpenAIDictionaryKey,
        EZOpenAISentenceKey,
        EZOpenAIServiceUsageStatusKey,
        EZOpenAIDomainKey,
        EZOpenAIModelKey,
        
        EZYoudaoTranslationKey,
        EZYoudaoDictionaryKey,
        
        EZDeepLAuthKey,
        EZDeepLTranslationAPIKey,
        
        EZDefaultTTSServiceKey,
    ];
}


#pragma mark -

- (NSString *)keyValuesOfServiceType:(EZServiceType)serviceType key:(NSString *)key value:(NSString *)value {
    /**
     easydict://writeKeyValue?ServiceType=OpenAI&ServiceUsageStatus=1
     
     easydict://writeKeyValue?OpenAIServiceUsageStatus=1
     
     easydict://writeKeyValue?OpenAIQueryServiceType=1
     */
    NSString *keyValueString = @"";
    
    NSArray *allowdKeyNames = @[
        EZServiceUsageStatusKey,
        EZQueryServiceTypeKey,
    ];
    
    NSArray *allServiceTypes = [EZServiceTypes allServiceTypes];
    
    BOOL validKey = [allServiceTypes containsObject:serviceType] && [allowdKeyNames containsObject:key];
    
    if (validKey) {
        NSString *keyString = [NSString stringWithFormat:@"%@%@", serviceType, key];
        keyValueString = [NSString stringWithFormat:@"%@=%@", keyString, value];
    }
    
    return keyValueString;
}

@end
