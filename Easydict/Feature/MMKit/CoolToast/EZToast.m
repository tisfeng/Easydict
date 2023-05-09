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

+ (void)showText:(NSString *)message toastPostion:(CTPosition)toastPostion {
    EZToast *toast = [EZToast toast];
    toast.toastPostion = toastPostion;
    toast.hiddenIcon = YES;
    toast.imageMarginLeft = 0;
    toast.labelMargin = 20;
    toast.minHeight = 35;

    [toast showCoolToast:message];
    toast.messageLabel.alignment = NSTextAlignmentLeft; // must set after showCoolText
}

+ (void)showSuccessToast {
    EZToast *toast = [EZToast toast];
    toast.toastPostion = CTPositionMouse;
    toast.toastBackgroundColor = [NSColor mm_colorWithHexString:@"#CDCDCD"];
    toast.textColor = [NSColor mm_colorWithHexString:@"#424242"];
    toast.hiddenIcon = YES;
    toast.imageMarginLeft = 0;
    toast.labelMargin = 5;
    toast.minHeight = 25;
    toast.minWidth = 25;
    toast.conerRadius = 5;
    toast.messageLabel.font = [NSFont systemFontOfSize:18 weight:NSFontWeightBlack];

    [toast showCoolToast:@"✓"]; // ✓  ✔︎
    toast.messageLabel.alignment = NSTextAlignmentCenter; // must set after showCoolText
}

@end
