//
//  EZMainQueryWindow.h
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZBaseQueryWindow.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZMainQueryWindow : EZBaseQueryWindow

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
