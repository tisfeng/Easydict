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

@property (nonatomic, copy) EZLanguage autoSelectedLanguage;

@property (nonatomic, strong) NSTextField *textField;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong, nullable) NSMenu *customMenu;
@property (nonatomic, copy) void (^menuItemSeletedBlock)(EZLanguage selectedLanguage);

- (void)showSelectedLanguage:(EZLanguage)language;

@end

NS_ASSUME_NONNULL_END
