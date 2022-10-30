//
//  TranslateWindow.h
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// It's critical to have a `NSPanel` window with `nonactivatingPanel` style mask.
// Also, make sure to override `canBecomeKey` to allow window to become key.

@interface TranslateWindow : NSPanel

@end

NS_ASSUME_NONNULL_END
