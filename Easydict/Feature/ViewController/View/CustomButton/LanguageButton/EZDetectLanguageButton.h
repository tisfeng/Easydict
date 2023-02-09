//
//  EZDetectLanguageButton.h
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZButton.h"
#import "EZLanguageManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZDetectLanguageButton : EZButton

@property (nonatomic, copy) EZLanguage detectedLanguage;
@property (nonatomic, assign) BOOL showAutoLanguage;

@property (nonatomic, copy) void (^menuItemSeletedBlock)(EZLanguage selectedLanguage);

@end

NS_ASSUME_NONNULL_END
