//
//  EZToast.h
//  Easydict
//
//  Created by tisfeng on 2023/5/8.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoolToast.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZToast : ToastWindowController

+ (EZToast *)toast;

/// Show toast, message with App icon.
+ (void)showToast:(NSString *)message;

/// Show only text.
+ (void)showText:(NSString *)message;

+ (void)showText:(NSString *)message toastPostion:(CTPosition)toastPostion;

+ (void)showSuccessToast;

@end

NS_ASSUME_NONNULL_END
