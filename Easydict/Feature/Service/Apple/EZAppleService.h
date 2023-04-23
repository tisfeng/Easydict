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

- (EZLanguage)languageEnumFromAppleLanguage:(NLLanguage)langString;
- (NLLanguage)appleLanguageFromLanguageEnum:(EZLanguage)lang;

- (NSSpeechSynthesizer *)playTextAudio:(NSString *)text fromLanguage:(EZLanguage)fromLanguage;

@end

NS_ASSUME_NONNULL_END
