//
//  EZBaseQueryWindow.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZBaseQueryViewController.h"
#import "EZTitlebar.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZBaseQueryWindow : NSWindow

@property (nonatomic, strong) EZTitlebar *titleBar;

@property (nonatomic, strong) EZBaseQueryViewController *viewController;

@end

NS_ASSUME_NONNULL_END
