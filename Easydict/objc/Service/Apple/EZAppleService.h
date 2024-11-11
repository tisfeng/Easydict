//
//  EZAppleService.h
//  Easydict
//
//  Created by tisfeng on 2022/11/29.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryService.h"
#import <NaturalLanguage/NaturalLanguage.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZAppleService : EZQueryService

+ (instancetype)shared;

- (EZLanguage)languageEnumFromAppleLanguage:(NLLanguage)appleLanguage;
- (NLLanguage)appleLanguageFromLanguageEnum:(EZLanguage)lang;

- (NSSpeechSynthesizer *)playTextAudio:(NSString *)text textLanguage:(EZLanguage)fromLanguage;

- (EZLanguage)detectText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
