//
//  EZOpenAIService.m
//  Easydict
//
//  Created by tisfeng on 2023/2/24.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZOpenAIService.h"
#import "NSString+EZUtils.h"
#import "EZConfiguration.h"
#import "EZOpenAIChatResponse.h"
#import "EZOpenAILikeService+EZPromptMessages.h"
#import "Easydict-Swift.h"

@interface EZOpenAIService ()

@end


@implementation EZOpenAIService

- (instancetype)init {
    if (self = [super init]) {
        self.defaultModel = @"gpt-3.5-turbo-1106";
    }
    return self;
}

- (NSString *)apiKey {
    // easydict://writeKeyValue?EZOpenAIAPIKey=
    
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:EZOpenAIAPIKey] ?: @"";
    return apiKey;
}

- (NSString *)endPoint {
    NSString *endPoint = [[NSUserDefaults standardUserDefaults] stringForKey:EZOpenAIEndPointKey] ?: @"";
    if (endPoint.length == 0) {
        endPoint = @"https://api.openai.com/v1/chat/completions";
    }
    return endPoint;
}

- (NSString *)model {
    // easydict://writeKeyValue?EZOpenAIModelKey=
    
    NSString *model = [[NSUserDefaults standardUserDefaults] stringForKey:EZOpenAIModelKey];
    
    // If there is no own key, only the default model is allowed to be used, such as gemini-pro
    if (![self hasPrivateAPIKey]) {
    // In development mode, the default model is allowed to be modified.
#if !DEBUG
        model = self.defaultModel;
#endif
    }
    
    if (model.length == 0) {
        model = self.defaultModel;
    }
    
    return model;
}

#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeOpenAI;
}

- (EZQueryTextType)queryTextType {
    EZQueryTextType type = EZQueryTextTypeNone;
    BOOL enableTranslation = [[NSUserDefaults mm_readString:EZOpenAITranslationKey defaultValue:@"1"] boolValue];
    BOOL enableDictionary = [[NSUserDefaults mm_readString:EZOpenAIDictionaryKey defaultValue:@"1"] boolValue];
    BOOL enableSentence = [[NSUserDefaults mm_readString:EZOpenAISentenceKey defaultValue:@"1"] boolValue];
    if (enableTranslation) {
        type = type | EZQueryTextTypeTranslation;
    }
    if (enableDictionary) {
        type = type | EZQueryTextTypeDictionary;
    }
    if (enableSentence) {
        type = type | EZQueryTextTypeSentence;
    }
    if (type == EZQueryTextTypeNone) {
        type = EZQueryTextTypeTranslation;
    }
    
    return type;
}

- (EZQueryTextType)intelligentQueryTextType {
    EZQueryTextType type = [Configuration.shared intelligentQueryTextTypeForServiceType:self.serviceType];
    return type;
}

- (EZServiceUsageStatus)serviceUsageStatus {
    EZServiceUsageStatus serviceUsageStatus = [[NSUserDefaults mm_readString:EZOpenAIServiceUsageStatusKey defaultValue:@"0"] integerValue];
    return serviceUsageStatus;
}

- (NSString *)name {
    return EZLocalizedString(@"openai_translate");
}

- (NSString *)link {
    return @"https://chat.openai.com";
}

// Supported languages, key is EZLanguage, value is the same as the key.
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] init];
    
    NSArray<EZLanguage> *allLanguages = [EZLanguageManager.shared allLanguages];
    for (EZLanguage language in allLanguages) {
        NSString *value = language;
        if ([language isEqualToString:EZLanguageClassicalChinese]) {
            value = kEZLanguageWenYanWen;
        }
        
        // OpenAI does not support Burmese 🥲
        if (![language isEqualToString:EZLanguageBurmese]) {
            [orderedDict setObject:value forKey:language];
        }
    }
    
    return orderedDict;
}

- (BOOL)hasPrivateAPIKey {
    return ![self.apiKey isEqualToString:self.defaultAPIKey];
}

@end
