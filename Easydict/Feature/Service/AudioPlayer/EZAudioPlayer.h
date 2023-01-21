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

/// Play text audio with designated service.
- (void)playTextAudio:(NSString *)text fromLanguage:(EZLanguage)language serive:(EZQueryService *)service;

/// Directly play audio url.
- (void)playWord:(NSString *)word audioURL:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
