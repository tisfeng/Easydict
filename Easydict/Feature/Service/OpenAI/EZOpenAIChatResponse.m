//
//  EZOpenAIChatResponseModel.m
//  Easydict
//
//  Created by tisfeng on 2023/12/25.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZOpenAIChatResponse.h"

@implementation EZOpenAIChatResponse

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"ID" : @"id",
        @"systemFingerprint" : @"system_fingerprint",
    };
}

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"choices" : EZOpenAIChoice.class,
    };
}

@end


@implementation EZOpenAIChoice

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"finishReason" : @"finish_reason",
    };
}

@end

@implementation EZOpenAIDelta
@end


@implementation EZOpenAIMessage
@end

@implementation EZOpenAIUsage

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"promptTokens" : @"prompt_tokens",
        @"completionTokens" : @"completion_tokens",
        @"textTokens" : @"text_tokens",
    };
}

@end

@implementation EZOpenAIErrorResponse
@end

@implementation EZOpenAIError
@end
