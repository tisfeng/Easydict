//
//  EZBingTTSVoice.h
//  Easydict
//
//  Created by tisfeng on 2023/8/25.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Docs: https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/language-support?tabs=tts

@interface EZBingLanguageVoice : NSObject

@property (nonatomic, copy) NSString *lang; // BCP-47, en-US
@property (nonatomic, copy) NSString *voiceName; // en-US-JennyNeural

+ (instancetype)voiceWithLanguage:(NSString *)langauge voiceName:(NSString *)voiceName;

@end

NS_ASSUME_NONNULL_END
