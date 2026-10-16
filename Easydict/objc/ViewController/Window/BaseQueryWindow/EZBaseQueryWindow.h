//
//  EZBaseQueryWindow.h
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZBaseQueryViewController.h"
#import "EZTitlebar.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZBaseQueryWindow : NSPanel

@property (nonatomic, assign) EZWindowType windowType;
@property (nonatomic, strong) EZTitlebar *titleBar;
@property (nonatomic, assign, getter=isPin) BOOL pin;

@property (nonatomic, strong) EZBaseQueryViewController *queryViewController;

@property (nonatomic, copy) void (^resizeWindowBlock)(void);
@property (nonatomic, copy) void (^didBecomeKeyWindowBlock)(void);

- (instancetype)initWithWindowType:(EZWindowType)type;

- (void)updateWindowLevel:(BOOL)pin;

/// Restore custom titlebar controls after changing a mini panel's style mask.
- (void)rebuildTitlebar;

@end

NS_ASSUME_NONNULL_END
