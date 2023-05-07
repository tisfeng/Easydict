//
//  EZAudioButton.m
//  Easydict
//
//  Created by tisfeng on 2023/4/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZAudioButton.h"
#import "NSImage+EZResize.h"
#import "NSImage+EZSymbolmage.h"

@interface EZAudioButton ()

@property (nonatomic, assign) BOOL isPlaying;

@end

@implementation EZAudioButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.isPlaying = NO;

    mm_weakify(self);

    [self setClickBlock:^(EZButton *audioButton) {
        mm_strongify(self);
        BOOL isPlaying = self.audioPlayer.isPlaying;

        if (isPlaying) {
            [self.audioPlayer stop];
        } else {
            if (self.playAudioBlock) {
                self.playAudioBlock();
            }
        }
    }];
}

- (void)setAudioPlayer:(EZAudioPlayer *)audioPlayer {
    _audioPlayer = audioPlayer;
    
    mm_weakify(self);
    [audioPlayer setPlayingBlock:^(BOOL isPlaying) {
        mm_strongify(self);        
        self.isPlaying = isPlaying;
    }];
}

- (void)setIsPlaying:(BOOL)isPlaying {
    _isPlaying = isPlaying;
        
    NSString *action = isPlaying ? @"Stop" : @"Play";
    self.toolTip = [NSString stringWithFormat:@"%@ Audio", action];

//    NSString *symbolName = isPlaying ? @"pause.circle" : @"play.circle";
//    NSImage *audioImage = [NSImage ez_imageWithSymbolName:symbolName size:CGSizeMake(15, 15)];
    
    NSImage *playImage = [NSImage imageNamed:@"audio"];
    NSImage *pauseImage = [NSImage ez_imageWithSymbolName:@"pause.circle"];

    self.image = isPlaying ? pauseImage : playImage;

    [self excuteLight:^(NSButton *audioButton) {
        audioButton.image = [audioButton.image imageWithTintColor:[NSColor imageTintLightColor]];
    } dark:^(NSButton *audioButton) {
        audioButton.image = [audioButton.image imageWithTintColor:[NSColor imageTintDarkColor]];
    }];
    
    if (self.playStatus) {
        self.playStatus(isPlaying);
    }
}

- (void)setPlayStatus:(void (^)(BOOL))playStatus {
    _playStatus = playStatus;
    
    // init play status
    playStatus(self.isPlaying);
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
