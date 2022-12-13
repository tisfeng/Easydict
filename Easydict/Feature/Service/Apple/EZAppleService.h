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

- (void)playTextAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSError *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END
