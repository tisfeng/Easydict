//
//  NSView+EZHiddenWithAnimation.h
//  Easydict
//
//  Created by tisfeng on 2022/12/10.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSView (EZAnimatedHidden)

- (void)setAnimatedHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
