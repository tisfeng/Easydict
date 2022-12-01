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

@property (nonatomic, assign) BOOL autoCopyTranslateResult;
@property (nonatomic, assign) BOOL launchAtStartup;
@property (nonatomic, assign) BOOL automaticallyChecksForUpdates;

@property (nonatomic, copy) NSString *translateIdentifier;
@property (nonatomic, assign) EZLanguage from;
@property (nonatomic, assign) EZLanguage to;
@property (nonatomic, assign) BOOL isPin;
@property (nonatomic, assign) BOOL isFold;


+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
