//
//  PopUpButton.h
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PopUpButton : NSButton

DefineMethodMMMake_h(PopUpButton, button)

@property (nonatomic, strong) NSTextField *textField;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong, nullable) NSMenu *customMenu;
@property (nonatomic, copy) void(^menuItemSeletedBlock)(NSInteger index, NSString *title);

- (void)updateMenuWithTitleArray:(NSArray<NSString *> *)titles;
- (void)updateWithIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
