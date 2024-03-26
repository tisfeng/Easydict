//
//  MainWindow.h
//  Easydict
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZBaseQueryWindow.h"

NS_ASSUME_NONNULL_BEGIN

/// Fixed window alway show at the designated position, and it will keep previous query result. It can be resized window size.
@interface EZFixedQueryWindow : EZBaseQueryWindow

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
