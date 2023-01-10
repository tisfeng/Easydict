//
//  EZConfiguration.h
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageManager.h"

NS_ASSUME_NONNULL_BEGIN


@interface EZConfiguration : NSObject

@property (nonatomic, assign) BOOL autoSelectText;
@property (nonatomic, assign) BOOL launchAtStartup;
@property (nonatomic, assign) BOOL automaticallyChecksForUpdates;
@property (nonatomic, assign) BOOL hideMainWindow;
@property (nonatomic, assign) BOOL autoSnipTranslate;
@property (nonatomic, assign) BOOL autoPlayAudio;

@property (nonatomic, assign) EZLanguage from;
@property (nonatomic, assign) EZLanguage to;


+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
