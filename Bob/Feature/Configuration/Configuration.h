//
//  Configuration.h
//  Bob
//
//  Created by ripper on 2019/11/14.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslateLanguage.h"

NS_ASSUME_NONNULL_BEGIN

@interface Configuration : NSObject

@property (nonatomic, assign) BOOL autoCopyTranslateResult;
@property (nonatomic, assign) BOOL launchAtStartup;
@property (nonatomic, assign) BOOL automaticallyChecksForUpdates;

@property (nonatomic, copy) NSString *translateIdentifier;
@property (nonatomic, assign) Language from;
@property (nonatomic, assign) Language to;
@property (nonatomic, assign) BOOL isPin;
@property (nonatomic, assign) BOOL isFold;


+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
