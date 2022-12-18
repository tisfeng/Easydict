//
//  EZPopButton.h
//  Easydict
//
//  Created by tisfeng on 2022/11/24.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZButton.h"
#import "EZHoverButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZPopUpButton : EZHoverButton

DefineMethodMMMake_h(EZPopUpButton, button);

@property (nonatomic, strong) NSTextField *textField;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong, nullable) NSMenu *customMenu;
@property (nonatomic, copy) void (^menuItemSeletedBlock)(NSInteger index, NSString *title);

- (void)updateMenuWithTitleArray:(NSArray<NSString *> *)titles;
- (void)updateWithIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
