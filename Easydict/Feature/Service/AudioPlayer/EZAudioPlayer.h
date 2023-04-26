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
#import "EZQueryResult.h"

@class EZQueryService;

NS_ASSUME_NONNULL_BEGIN

@interface EZAudioPlayer : NSObject

@property (nonatomic, assign, readonly) BOOL playing;
@property (nonatomic, copy, nullable) void (^playingBlock)(BOOL isPlaying);

@property (nonatomic, assign) BOOL enableDownload;

@property (nonatomic, weak) EZQueryService *service;
@property (nonatomic, strong) EZQueryService *defaultTTSService;


- (void)playTextAudio:(NSString *)text textLanguage:(EZLanguage)language;

/// Play word phonetic
- (void)playWordPhonetic:(EZWordPhonetic *)wordPhonetic
             serviceType:(nullable EZServiceType)serviceType;

- (void)playTextAudio:(NSString *)text
         textLanguage:(EZLanguage)language
               accent:(nullable NSString *)accent
             audioURL:(nullable NSString *)audioURL
          serviceType:(nullable EZServiceType)serviceType;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
