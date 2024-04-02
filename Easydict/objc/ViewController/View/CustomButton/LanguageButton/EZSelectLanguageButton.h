//
//  EZSelectLanguageButton.h
//  Easydict
//
//  Created by tisfeng on 2022/12/2.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZHoverButton.h"
#import "EZLanguageManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZSelectLanguageButton : EZHoverButton

DefineMethodMMMake_h(EZSelectLanguageButton, button);

@property (nonatomic, copy) EZLanguage selectedLanguage;
@property (nonatomic, copy) EZLanguage autoSelectedLanguage;
@property (nonatomic, copy) NSString *autoChineseSelectedTitle; // 自动检测 --> 自动选择

@property (nonatomic, copy) void (^selectedMenuItemBlock)(EZLanguage selectedLanguage);

@property (nonatomic, assign, readonly) CGFloat buttonWidth;

@end

NS_ASSUME_NONNULL_END
