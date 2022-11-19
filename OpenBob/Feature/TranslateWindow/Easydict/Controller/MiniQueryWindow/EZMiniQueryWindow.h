//
//  EZMiniQueryWindow.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZBaseQueryWindow.h"
#import "EZBaseQueryViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZMiniQueryWindow : EZBaseQueryWindow

+ (instancetype)shared;

//@property (nonatomic, strong) EZBaseQueryViewController *viewController;


@end

NS_ASSUME_NONNULL_END
