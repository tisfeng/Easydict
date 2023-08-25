//
//  EZBingTTSVoice.m
//  Easydict
//
//  Created by tisfeng on 2023/8/25.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZBingLanguageVoice.h"

@implementation EZBingLanguageVoice

+ (instancetype)voiceWithLanguage:(NSString *)langauge voiceName:(NSString *)voiceName {
    EZBingLanguageVoice *voice = [[EZBingLanguageVoice alloc] init];
    voice.lang = langauge;
    voice.voiceName = voiceName;
    return voice;
}

@end
