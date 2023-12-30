//
//  EZPromptMessages.h
//  Easydict
//
//  Created by tisfeng on 2023/12/26.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZOpenAIService.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZOpenAIService (EZPromptMessages)

/// Translation messages.
- (NSArray *)translatioMessages:(NSString *)text from:(EZLanguage)sourceLanguage to:(EZLanguage)targetLanguage;

/// Sentence messages.
- (NSArray<NSDictionary *> *)sentenceMessages:(NSString *)sentence from:(EZLanguage)sourceLanguage to:(EZLanguage)targetLanguage;

/// Generate the prompt for the given word.
- (NSArray<NSDictionary *> *)dictMessages:(NSString *)word from:(EZLanguage)sourceLanguage to:(EZLanguage)targetLanguage;

@end

NS_ASSUME_NONNULL_END
