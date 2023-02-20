//
//  EZAudioPlayer.h
//  Easydict
//
//  Created by tisfeng on 2022/12/13.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageManager.h"
#import "EZQueryService.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZAudioPlayer : NSObject

/// Play system text audio.
- (void)playSystemTextAudio:(NSString *)text fromLanguage:(EZLanguage)from;

/// Play text URL audio.
- (void)playTextAudio:(NSString *)text
             audioURL:(nullable NSString *)audioURL
         fromLanguage:(EZLanguage)language
               serive:(nullable EZQueryService *)service;

@end

NS_ASSUME_NONNULL_END
