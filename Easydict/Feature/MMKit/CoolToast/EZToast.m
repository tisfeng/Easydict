//
//  EZToast.m
//  Easydict
//
//  Created by tisfeng on 2023/5/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZToast.h"

@implementation EZToast

+ (EZToast *)toast {
    return [self getToastWindow];
}

/// Show toast, message with App icon.
+ (void)showToast:(NSString *)message {
    EZToast *toast = [EZToast toast];
    [toast showCoolToast:message];
}

/// Show only text.
+ (void)showText:(NSString *)message {
    EZToast *toast = [EZToast toast];
    toast.hiddenIcon = YES;
    toast.imageMarginLeft = 0;
    toast.labelMargin = 20;
    toast.minHeight = 35;

    [toast showCoolToast:message];
    toast.messageLabel.alignment = NSTextAlignmentLeft; // must set after showCoolText
}


@end
