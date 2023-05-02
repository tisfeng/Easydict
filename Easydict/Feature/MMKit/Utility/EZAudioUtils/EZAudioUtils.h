//
//  EZAudioUtils.h
//  Easydict
//
//  Created by tisfeng on 2023/3/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZAudioUtils : NSObject

/// Get system volume, [0, 100]
+ (float)getSystemVolume;

/// Set system volume, [0, 100]
+ (void)setSystemVolume:(float)volume;

+ (void)getPlayingSongInfo;

+ (void)isPlayingAudio:(void(^)(BOOL isPlaying))completion;

@end

NS_ASSUME_NONNULL_END
