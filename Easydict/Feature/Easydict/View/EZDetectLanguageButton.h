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

@property (nonatomic, copy) EZLanguage language;

@property (nonatomic, copy) void (^menuItemSeletedBlock)(NSInteger index, NSString *title);

- (void)updateMenuWithTitleArray:(NSArray<NSString *> *)titles;
- (void)updateWithIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
