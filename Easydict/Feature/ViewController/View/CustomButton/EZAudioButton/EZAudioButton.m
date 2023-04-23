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
    self.toolTip = @"Play";
    self.isPlaying = NO;

    mm_weakify(self);

    [self setClickBlock:^(EZButton *_Nonnull audioButton) {
        mm_strongify(self);
        BOOL isPlaying = self.audioPlayer.playing;
        NSLog(@"audioActionBlock: %d", isPlaying);

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
        NSLog(@"isPlaying: %d", isPlaying);
        
        self.isPlaying = isPlaying;
    }];
}

- (void)setIsPlaying:(BOOL)isPlaying {
    _isPlaying = isPlaying;
    
    NSString *symbolName = isPlaying ? @"pause.circle" : @"play.circle";
    NSImage *audioImage = [NSImage ez_imageWithSymbolName:symbolName];
    self.image = audioImage;
    
    [self excuteLight:^(NSButton *audioButton) {
        audioButton.image = [audioButton.image imageWithTintColor:[NSColor imageTintLightColor]];
    } dark:^(NSButton *audioButton) {
        audioButton.image = [audioButton.image imageWithTintColor:[NSColor imageTintDarkColor]];
    }];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
