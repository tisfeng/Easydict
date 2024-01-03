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
#import "EZOpenAIService+EZPromptMessages.h"
#import "Easydict-Swift.h"

static NSString *const kEZLanguageWenYanWen = @"文言文";

@interface EZOpenAIService ()

@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *endPoint;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *domain;

@property (nonatomic, copy) NSString *defaultAPIKey;
@property (nonatomic, copy) NSString *defaultEndPoint;
@property (nonatomic, copy) NSString *defaultModel;

@end

@implementation EZOpenAIService

- (instancetype)init {
    if (self = [super init]) {
        /**
         For convenience, we provide a default key for users to try out the service.

         Please do not abuse it, otherwise it may be revoked.

         For better experience, please apply for your personal key at https://makersuite.google.com/app/apikey
         */
        
        // Only use Google Gemini-pro channel
        self.defaultAPIKey = [@"NnZp/jV9prt5empCOJIM8LmzHmFdTiVa4i+mURU8t+uGpT+nDt/JTdf14JglJLEwVm8Sup83uzJjMANeEvyPcw==" decryptAES];
        
#if DEBUG
        self.defaultAPIKey = [@"NnZp/jV9prt5empCOJIM8LmzHmFdTiVa4i+mURU8t+uGpT+nDt/JTdf14JglJLEwpXkkSw+uGgiE8n5skqDdjQ==" decryptAES];
#endif
        self.defaultEndPoint = [@"gTYTMVQTyMU0ogncqcMNRo/TDhten/V4TqX4IutuGNcYTLtxjgl/aXB/Y1NXAjz2" decryptAES];
        self.defaultModel = [self hasPrivateAPIKey] ? @"gpt-3.5-turbo-1106" : @"gemini-pro";
    }
    return self;
}

- (NSString *)apiKey {
    // easydict://writeKeyValue?EZOpenAIAPIKey=
    
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:EZOpenAIAPIKey] ?: @"";
    if (apiKey.length == 0 && EZConfiguration.shared.isBeta) {
        apiKey = self.defaultAPIKey;
    }
    return apiKey;
}

- (NSString *)endPoint {
    // easydict://writeKeyValue?EZOpenAIEndPointKey=
    
    NSString *endPoint = [NSUserDefaults mm_readString:EZOpenAIEndPointKey defaultValue:@""];
    if (endPoint.length == 0) {
        endPoint = [NSString stringWithFormat:@"https://%@/v1/chat/completions", self.domain];
    }
    if (![self hasPrivateAPIKey]) {
        endPoint = self.defaultEndPoint;
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

- (NSString *)domain {
    // easydict://writeKeyValue?EZOpenAIDomainKey=
    
    NSString *defaultDomain = @"api.openai.com";
    NSString *domain = [NSUserDefaults mm_readString:EZOpenAIDomainKey defaultValue:defaultDomain];
    if (domain.length == 0) {
        domain = defaultDomain;
    }
    return domain;
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
    EZQueryTextType type = [EZConfiguration.shared intelligentQueryTextTypeForServiceType:self.serviceType];
    return type;
}

- (EZServiceUsageStatus)serviceUsageStatus {
    EZServiceUsageStatus serviceUsageStatus = [[NSUserDefaults mm_readString:EZOpenAIServiceUsageStatusKey defaultValue:@"0"] integerValue];
    return serviceUsageStatus;
}

- (NSString *)name {
    return NSLocalizedString(@"openai_translate", nil);
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

/// Use OpenAI to translate text.
- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *, NSError *_Nullable))completion {
    text = [text removeInvisibleChar];
    
    NSString *sourceLanguage = [self languageCodeForLanguage:from];
    NSString *targetLanguage = [self languageCodeForLanguage:to];
    
    NSString *sourceLanguageType = [self getChineseLanguageType:sourceLanguage accordingToLanguage:targetLanguage];
    NSString *targetLanguageType = [self getChineseLanguageType:targetLanguage accordingToLanguage:sourceLanguage];
    
    if ([sourceLanguageType isEqualToString:EZLanguageAuto]) {
        // If source languaeg is auto, just ignore, OpenAI can handle it automatically.
        sourceLanguageType = @"";
    }
    
    BOOL stream = YES;
    NSMutableDictionary *parameters = @{
        @"model" : self.model,
        @"temperature" : @(0),
        @"top_p" : @(1.0),
        @"frequency_penalty" : @(1),
        @"presence_penalty" : @(1),
        @"stream" : @(stream),
    }.mutableCopy;
    
    EZQueryTextType queryServiceType = EZQueryTextTypeTranslation;
    
    BOOL enableDictionary = self.queryTextType & EZQueryTextTypeDictionary;
    BOOL isQueryDictionary = NO;
    if (enableDictionary) {
        isQueryDictionary = [text shouldQueryDictionaryWithLanguage:from maxWordCount:2];
    }
    
    BOOL enableSentence = self.queryTextType & EZQueryTextTypeSentence;
    BOOL isQueryEnglishSentence = NO;
    if (!isQueryDictionary && enableSentence) {
        BOOL isEnglishText = [from isEqualToString:EZLanguageEnglish];
        if (isEnglishText) {
            isQueryEnglishSentence = [text shouldQuerySentenceWithLanguage:from];
        }
    }
    
    BOOL enableTranslation = self.queryTextType & EZQueryTextTypeTranslation;
    
    self.result.from = from;
    self.result.to = to;
    
    NSArray<NSDictionary *> *messages = nil;
    if (isQueryDictionary) {
        queryServiceType = EZQueryTextTypeDictionary;
        messages = [self dictMessages:text from:sourceLanguageType to:targetLanguageType];
    } else if (isQueryEnglishSentence) {
        queryServiceType = EZQueryTextTypeSentence;
        messages = [self sentenceMessages:text from:sourceLanguageType to:targetLanguageType];
    } else if (enableTranslation) {
        queryServiceType = EZQueryTextTypeTranslation;
        messages = [self translatioMessages:text from:sourceLanguageType to:targetLanguageType];
    }
    parameters[@"messages"] = messages;
    
    if (queryServiceType != EZQueryTextTypeNone) {
        [self startChat:parameters
                 stream:stream
       queryServiceType:queryServiceType
             completion:^(NSString *_Nullable result, NSError *_Nullable error) {
            [self handleResultText:result error:error queryServiceType:queryServiceType completion:completion];
        }];
    }
}

#pragma mark - Start chat

- (void)startChat:(NSDictionary *)parameters
           stream:(BOOL)stream
 queryServiceType:(EZQueryTextType)queryServiceType
       completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion
{
    NSString *openaiKey = self.apiKey;
    NSDictionary *header = @{
        // OpenAI docs: https://platform.openai.com/docs/api-reference/chat/create
        @"Content-Type" : @"application/json",
        @"Authorization" : [NSString stringWithFormat:@"Bearer %@", openaiKey],
        // support azure open ai, Ref: https://learn.microsoft.com/zh-cn/azure/cognitive-services/openai/chatgpt-quickstart?tabs=bash&pivots=rest-api
        @"api-key" : openaiKey,
    };
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    if (stream) {
        // If stream = YES, We don't need AFJSONResponseSerializer by default, we need original AFHTTPResponseSerializer, and set text/event-stream for Content-Type manually.
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[ @"text/event-stream" ]];
        manager.responseSerializer = responseSerializer;
    }
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.requestSerializer.timeoutInterval = EZNetWorkTimeoutInterval;
    [header enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
    
    BOOL shouldHandleQuote = NO;
    if (queryServiceType == EZQueryTextTypeTranslation) {
        shouldHandleQuote = YES;
    }
    
    // TODO: need to optimize.
    if (stream) {
        __block NSMutableString *mutableContent = [NSMutableString string];
        __block BOOL isFirstContent = YES;
        __block BOOL isFinished = NO;
        __block NSData *lastData;
        __block NSString *appendSuffixQuote = nil;
        
        [manager setDataTaskDidReceiveDataBlock:^(NSURLSession *_Nonnull session, NSURLSessionDataTask *_Nonnull dataTask, NSData *_Nonnull data) {
            if ([self.queryModel isServiceStopped:self.serviceType]) {
                return;
            }
            
            // convert data to JSON
            
            NSError *error;
            NSString *content = [self parseContentFromStreamData:data
                                                        lastData:&lastData
                                                           error:&error
                                                      isFinished:&isFinished];
            self.result.isFinished = isFinished;
            
            if (error && error.code != NSURLErrorCancelled) {
                completion(nil, error);
                return;
            }
            
            //            NSLog(@"content: %@, isFinished: %d", content, isFinished);
            
            NSString *appendContent = content;
            
            // It's strange that sometimes the `first` char and the `last` char is empty @"" 😢
            if (shouldHandleQuote) {
                if (isFirstContent && ![self.queryModel.queryText hasPrefixQuote]) {
                    appendContent = [content tryToRemovePrefixQuote];
                    
                    // Maybe there is only one content, it is the first stream content, and then finished.
                    if (isFinished) {
                        appendContent = [appendContent tryToRemoveSuffixQuote];
                    }
                }
                
                if (!isFinished) {
                    if (!isFirstContent) {
                        // Append last delayed suffix quote.
                        if (appendSuffixQuote) {
                            [mutableContent appendString:appendSuffixQuote];
                            appendSuffixQuote = nil;
                        }
                        
                        appendSuffixQuote = [content suffixQuote];
                        // If content has suffix quote, mark it, delay append suffix quote, in case the suffix quote is in the extra last char.
                        if (appendSuffixQuote) {
                            appendContent = [content tryToRemoveSuffixQuote];
                        }
                    }
                } else {
                    // [DONE], end of string.
                    if (![self.queryModel.queryText hasSuffixQuote]) {
                        appendContent = [appendContent tryToRemoveSuffixQuote];
                    } else if (appendSuffixQuote) {
                        appendContent = [content stringByAppendingString:appendSuffixQuote];
                    }
                }
                
                // Maybe the content is a empty text @""
                if (content.length == 0) {
                    if (isFirstContent) {
                        // Set isFirst = YES, this is a invalid content.
                        isFirstContent = YES;
                    }
                    
                    if (isFinished) {
                        // If last conent is @"", try to remove mutableContent last suffix quotes.
                        if (![self.queryModel.queryText hasSuffixQuote]) {
                            completion([mutableContent tryToRemoveSuffixQuote], nil);
                            return;
                        }
                    }
                } else {
                    isFirstContent = NO;
                }
            }
            
            if (appendContent) {
                [mutableContent appendString:appendContent];
            }
            
            // Do not callback when mutableString length is 0 when isFinished is NO, to avoid auto hide reuslt view.
            if (isFinished || mutableContent.length) {
                completion(mutableContent, nil);
            }
            
//              NSLog(@"mutableContent: %@", mutableContent);
        }];
    }
    
    NSURLSessionTask *task = [manager POST:self.endPoint parameters:parameters progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }
        
        NSString *result = self.result.translatedText;
        if (!stream) {
            EZOpenAIChatResponse *responseModel = [EZOpenAIChatResponse mj_objectWithKeyValues:responseObject];
            EZOpenAIChoice *choice = responseModel.choices.firstObject;
            result = choice.message.content;
        }
        
        if (![self.queryModel.queryText hasQuotesPair] && [result hasQuotesPair]) {
            result = [result tryToRemoveQuotes];
        }
        completion(result, nil);
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (error.code == NSURLErrorCancelled) {
            return;
        }
        
        EZError *ezError = [self getEZErrorMessageWithError:error];
        completion(nil, ezError);
    }];
    
    [self.queryModel setStopBlock:^{
        [task cancel];
    } serviceType:self.serviceType];
}

/// Parse content from nsdata
- (NSString *)parseContentFromStreamData:(NSData *)data
                                lastData:(NSData **)lastData
                                   error:(NSError **)error
                              isFinished:(BOOL *)isFinished {
    /**
     data: {"id":"chatcmpl-6uN6CP9w98STOanV3GidjEr9eNrJ7","object":"chat.completion.chunk","created":1678893180,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"role":"assistant"},"index":0,"finish_reason":null}]}
     
     data: {"id":"chatcmpl-6uN6CP9w98STOanV3GidjEr9eNrJ7","object":"chat.completion.chunk","created":1678893180,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"\n\n"},"index":0,"finish_reason":null}]}
     
     data: {"id":"chatcmpl-6vH0XCFkVoEtnuYzrc70ZMZsD92pt","object":"chat.completion.chunk","created":1679108093,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{},"index":0,"finish_reason":"stop"}]}
     
     data: [DONE]
     */
    
    /**
     
     Note: Sometimes the json data obtained from Azure Open AI through stream is a unterminated json.
     so join the next json data together with previous json data, then perform json serialization
     
     data: {"id":"chatcmpl-7uYwHX8kYxs4UuvxpA9qGj8g0w76w","object":"chat.completion.chunk","created":1693715029,"model":"gpt-35-turbo","choices":[{"index":0,"finish_reason":null,"delta":{"content":
     
     */
    
    if (lastData && *lastData) {
        NSMutableData *mutableData = [NSMutableData dataWithData:*lastData];
        [mutableData appendData:data];
        data = mutableData;
    }
    
    // Convert data to string
    NSString *jsonDataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //        NSLog(@"jsonDataString: %@", jsonDataString);
    
    // OpenAI docs: https://platform.openai.com/docs/api-reference/chat/create
    
    // split string to array
    NSString *dataKey = @"data:";
    NSString *terminationFlag = @"[DONE]";
    NSArray *jsonArray = [jsonDataString componentsSeparatedByString:dataKey];
    //        NSLog(@"jsonArray: %@", jsonArray);
    
    NSMutableString *mutableString = [NSMutableString string];
    
    // iterate array
    for (NSString *jsonString in jsonArray) {
        if (isFinished) {
            *isFinished = NO;
        }
        
        NSString *dataString = [jsonString trim];
        if (dataString.length) {
            if ([dataString isEqualToString:terminationFlag]) {
                if (isFinished) {
                    *isFinished = YES;
                }
                break;
            }
            
            // parse string to json
            NSData *jsonData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
            if (jsonError) {
                // the error is a unterminated json error
                if (jsonError.domain == NSCocoaErrorDomain && jsonError.code == 3840) {
                    //                    NSLog(@"\n\nincomplete dataString: %@\n\n", dataString);
                    
                    NSString *incompleteDataString = [NSString stringWithFormat:@"%@\n%@", dataKey, dataString];
                    NSData *incompleteData = [incompleteDataString dataUsingEncoding:NSUTF8StringEncoding];
                    if (lastData) {
                        *lastData = incompleteData;
                    }
                } else {
                    *error = jsonError;
                    NSLog(@"json error: %@", *error);
                    NSLog(@"dataString: %@", dataString);
                }
                
                break;
            } else {
                if (lastData) {
                    *lastData = nil;
                }
            }
            
            EZOpenAIChatResponse *responseModel = [EZOpenAIChatResponse mj_objectWithKeyValues:json];
            EZOpenAIChoice *choice = responseModel.choices.firstObject;
            NSString *content = choice.delta.content;
            //  NSLog(@"delta content: %@", content);
            
            /**
             SIGABRT: -[NSNull length]: unrecognized selector sent to instance 0x1dff03ce0
             
             -[__NSCFString appendString:]
             -[EZOpenAIService parseContentFromStreamData:lastData:error:isFinished:] EZOpenAIService.m:536
             */
            if ([content isKindOfClass:NSString.class]) {
                [mutableString appendString:content];
            }
            
            // finish_reason is string or null
            NSString *finishReason = choice.finishReason;
            
            // Fix: SIGABRT: -[NSNull length]: unrecognized selector sent to instance 0x1dff03ce0
            if ([finishReason isKindOfClass:NSString.class] && finishReason.length) {
                NSLog(@"finish reason: %@", finishReason);
                
                /**
                 The reason the model stopped generating tokens.
                 
                 This will be "stop" if the model hit a natural stop point or a provided stop sequence,
                 "length" if the maximum number of tokens specified in the request was reached,
                 "content_filter" if content was omitted due to a flag from our content filters,
                 "tool_calls" if the model called a tool,
                 or "function_call" (deprecated) if the model called a function.
                 */
                if (isFinished) {
                    *isFinished = YES;
                }
                break;
            }
        }
    }
    
    return mutableString;
}

- (void)handleResultText:(NSString *)resultText
                   error:(NSError *)error
        queryServiceType:(EZQueryTextType)queryServiceType
              completion:(void (^)(EZQueryResult *, NSError *_Nullable))completion {
    NSArray *normalResults = [[resultText trim] toParagraphs];
    
    switch (queryServiceType) {
        case EZQueryTextTypeTranslation:
        case EZQueryTextTypeSentence: {
            self.result.translatedResults = normalResults;
            completion(self.result, error);
            break;
        }
        case EZQueryTextTypeDictionary: {
            if (error) {
                self.result.showBigWord = NO;
                self.result.translateResultsTopInset = 0;
                completion(self.result, error);
                return;
            }
            
            self.result.translatedResults = normalResults;
            self.result.showBigWord = YES;
            self.result.queryText = self.queryModel.queryText;
            self.result.translateResultsTopInset = 6;
            completion(self.result, error);
            break;
        }
        default:
            completion(self.result, nil);
            break;
    }
}

- (EZError *)getEZErrorMessageWithError:(NSError *)error {
    EZError *ezError = [EZError errorWithNSError:error];
    NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    EZOpenAIErrorResponse *errorResponse = [EZOpenAIErrorResponse mj_objectWithKeyValues:errorData.mj_JSONObject];
    NSString *errorMessage = errorResponse.error.message;
    
    // in theory, message is a string. The code ensures its robustness here.
    if ([errorMessage isKindOfClass:NSString.class] && errorMessage.length) {
        ezError.errorDataMessage = errorMessage;
    }
    
    return ezError;
}

#pragma mark -

/// Get Chinese language type when the source language is classical Chinese.
- (NSString *)getChineseLanguageType:(NSString *)language accordingToLanguage:(NSString *)accordingToLanguage {
    if ([accordingToLanguage isEqualToString:kEZLanguageWenYanWen]) {
        if ([language isEqualToString:EZLanguageSimplifiedChinese]) {
            return @"简体白话文";
        }
        if ([language isEqualToString:EZLanguageTraditionalChinese]) {
            return @"繁体白话文";
        }
    }
    return language;
}

@end
