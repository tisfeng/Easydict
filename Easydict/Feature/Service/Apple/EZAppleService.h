//
//  EZAppleService.h
//  Easydict
//
//  Created by tisfeng on 2022/11/29.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryService.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZAppleService : EZQueryService

- (EZLanguage)appleLanguageEnumFromCode:(NSString *)langString;
- (NSString *)appleLanguageCodeForLanguage:(EZLanguage)lang;

- (void)playTextAudio:(NSString *)text fromLanguage:(EZLanguage)from;

@end

NS_ASSUME_NONNULL_END
