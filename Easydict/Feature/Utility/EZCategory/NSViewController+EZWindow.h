//
//  NSViewController+EZWindow.h
//  Easydict
//
//  Created by tisfeng on 2023/4/19.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSViewController (EZWindow)

- (nullable NSWindow *)window;

@end

NS_ASSUME_NONNULL_END
