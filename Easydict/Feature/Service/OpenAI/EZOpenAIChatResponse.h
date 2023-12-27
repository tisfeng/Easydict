//
//  EZOpenAIChatResponseModel.h
//  Easydict
//
//  Created by tisfeng on 2023/12/25.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EZOpenAIChatResponse;
@class EZOpenAIChoice;
@class EZOpenAIDelta;
@class EZOpenAIMessage;
@class EZOpenAIError;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

/**
 Chat stream response

 https://platform.openai.com/docs/api-reference/chat/streaming

 {
     "id": "chatcmpl-8XWvKM0CJ0oQwpfxw9F0a2FradxZK",
     "object": "chat.completion.chunk",
     "created": 1703002074,
     "model": "gpt-3.5-turbo-0613",
     "system_fingerprint": null,
     "choices": [
         {
             "index": 0,
             "delta": {
                 "role": "assistant",
                 "content": ""
             },
             "logprobs": null,
             "finish_reason": null
         }
     ]
 }
 */

@interface EZOpenAIChatResponse : NSObject
@property (nonatomic, copy) NSString *ID;
@property (nonatomic, copy) NSString *object;
@property (nonatomic, assign) NSInteger created;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy, nullable) NSString *systemFingerprint;
@property (nonatomic, copy) NSArray<EZOpenAIChoice *> *choices;
@end

@interface EZOpenAIChoice : NSObject
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) EZOpenAIDelta *delta;
@property (nonatomic, strong) EZOpenAIMessage *message;

@property (nonatomic, copy, nullable) id logprobs;
@property (nonatomic, copy, nullable) NSString *finishReason;
@end

// chat chuck
@interface EZOpenAIDelta : NSObject
@property (nonatomic, copy) NSString *role;
@property (nonatomic, copy) NSString *content;
@end


// chat completion
@interface EZOpenAIMessage : NSObject
@property (nonatomic, copy) NSString *role;
@property (nonatomic, copy) NSString *content;
@end

@interface EZOpenAIUsage : NSObject
@property (nonatomic, assign) NSInteger promptTokens;
@property (nonatomic, assign) NSInteger completionTokens;
@property (nonatomic, assign) NSInteger totalTokens;
@end

/**
 error response data

 {
   "error": {
     "code": "invalid_api_key",
     "message": "Incorrect API key provided: sk-5DJ2b***************************************7ckC. You can find your API key at https://platform.openai.com/account/api-keys.",
     "param": null,
     "type": "invalid_request_error"
   }
 }
 */

@interface EZOpenAIErrorResponse : NSObject
@property (nonatomic, strong) EZOpenAIError *error;
@end

@interface EZOpenAIError : NSObject
@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, nullable, copy) id param;
@property (nonatomic, copy) NSString *type;
@end

NS_ASSUME_NONNULL_END
