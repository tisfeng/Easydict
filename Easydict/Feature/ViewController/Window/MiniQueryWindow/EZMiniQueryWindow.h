//
//  EZMiniQueryWindow.h
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZBaseQueryWindow.h"

NS_ASSUME_NONNULL_BEGIN


/// Mini window alway show at the mouse location, it won't keep previous query result and can't be resized window size.
@interface EZMiniQueryWindow : EZBaseQueryWindow

@end

NS_ASSUME_NONNULL_END
