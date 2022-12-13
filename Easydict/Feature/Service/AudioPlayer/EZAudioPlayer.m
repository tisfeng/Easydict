//
//  EZAudioPlayer.m
//  Easydict
//
//  Created by tisfeng on 2022/12/13.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZAudioPlayer.h"
#import "EZAppleService.h"
#import <AVFoundation/AVFoundation.h>

@interface EZAudioPlayer ()

@property (nonatomic, strong) EZAppleService *appleService;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation EZAudioPlayer

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark - Getter

- (EZAppleService *)appleService {
    if (!_appleService) {
        _appleService = [[EZAppleService alloc] init];
    }
    return _appleService;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

#pragma mark - Public Mehods

/// Play system text audio.
- (void)playSystemTextAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(nullable void (^)(NSError *_Nullable))completion {
    [self.appleService playTextAudio:text fromLanguage:from completion:completion];
}

/// Play text audio with designated service.
- (void)playTextAudio:(NSString *)text fromLanguage:(EZLanguage)language serive:(EZQueryService *)service {
    if (!text.length) {
        NSLog(@"playTextAudio is empty");
        return;
    }
    
    mm_weakify(self)
    [service textToAudio:text fromLanguage:language completion:^(NSString *_Nullable url, NSError *_Nullable error) {
        mm_strongify(self);
        if (!error) {
            [self playAudioURL:url];
        } else {
            MMLogInfo(@"获取音频 URL 失败 %@", error);
        }
    }];
}

/// Directly play audio url.
- (void)playAudioURL:(NSString *)url {
    MMLogInfo(@"播放音频 %@", url);
    [self.player pause];
    if (!url.length) {
        return;
    }
    
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]]];
    [self.player play];
}

@end
