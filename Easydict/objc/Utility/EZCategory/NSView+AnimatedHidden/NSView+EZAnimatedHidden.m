//
//  NSView+EZHiddenWithAnimation.m
//  Easydict
//
//  Created by tisfeng on 2022/12/10.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSView+EZAnimatedHidden.h"

static CGFloat const kHiddenAnimationDuration = 0.3;

@implementation NSView (EZAnimatedHidden)

- (void)setAnimatedHidden:(BOOL)hidden {
    CGFloat alphaValue = hidden ? 0 : 1.0;
    if (self.alphaValue == alphaValue) {
        return;
    }
        
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = kHiddenAnimationDuration;
        self.animator.alphaValue = alphaValue;
    } completionHandler:^{
        self.hidden = hidden;
    }];
}

@end
