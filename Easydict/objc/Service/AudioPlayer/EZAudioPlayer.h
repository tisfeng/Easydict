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
@class EZWordPhonetic;

NS_ASSUME_NONNULL_BEGIN

@interface EZAudioPlayer : NSObject

@property (nonatomic, assign, readonly) BOOL isPlaying;
@property (nonatomic, copy, nullable) void (^playingBlock)(BOOL isPlaying);

@property (nonatomic, assign) BOOL enableDownload;

/// use system tts when play failed
@property (nonatomic, assign) BOOL useSystemTTSWhenPlayFailed;  // default is YES


// If not sepecify service, it will be defaultTTSService.
@property (nonatomic, weak) EZQueryService *service;

@property (nonatomic, strong, readonly) EZQueryService *defaultTTSService;

- (void)playWordPhonetic:(EZWordPhonetic *)wordPhonetic
       designatedService:(nullable EZQueryService *)designatedService;

- (void)playTextAudio:(NSString *)text textLanguage:(EZLanguage)language;

/// Play audio, perfer to use designatedService, else use self.service
- (void)playTextAudio:(NSString *)text
             language:(EZLanguage)language
               accent:(nullable NSString *)accent
             audioURL:(nullable NSString *)audioURL
    designatedService:(nullable EZQueryService *)designatedService;

- (void)stop;


// Get word audio file path
- (NSString *)getWordAudioFilePath:(NSString *)word
                          language:(EZLanguage)language
                            accent:(nullable NSString *)accent
                       serviceType:(EZServiceType)serviceType;

@end

NS_ASSUME_NONNULL_END
