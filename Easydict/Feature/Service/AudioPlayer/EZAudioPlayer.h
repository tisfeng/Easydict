//
//  EZAudioPlayer.h
//  Easydict
//
//  Created by tisfeng on 2022/12/13.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageManager.h"
#import "EZEnumTypes.h"

@class EZQueryService;

NS_ASSUME_NONNULL_BEGIN

@interface EZAudioPlayer : NSObject

@property (nonatomic, assign, readonly) BOOL playing;

@property (nonatomic, weak) EZQueryService *service;

@property (nonatomic, copy, nullable) void (^playingBlock)(BOOL isPlaying);

/// Play system text audio.
- (void)playSystemTextAudio:(NSString *)text textLanguage:(EZLanguage)from;

/// Play text URL audio.
- (void)playTextAudio:(NSString *)text
             audioURL:(nullable NSString *)audioURL
         textLanguage:(EZLanguage)language;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
